// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AspectModel.sol";

function getBitStorage(bytes storage bts, uint idx) view returns(bool) {
  return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
}

function setBitStorage(bytes storage bts, uint idx) {
  uint byte_idx = idx / 8;
  bytes1 bit    = toBit(idx % 8);
  uint len      = bts.length;
  if (byte_idx < len) {
    bts[byte_idx] = bts[byte_idx] | bit;
  } else {
    for (; len < byte_idx; len++) bts.push();
    bts.push() = bit;
  }
}

function unsetBitStorage(bytes storage bts, uint idx) {
  uint byte_idx = idx / 8;
  if (byte_idx >= bts.length) return;
  bts[byte_idx] = bts[byte_idx] & ~toBit(idx % 8);
}

using { getBitStorage, setBitStorage, unsetBitStorage } for bytes;

contract Aspect is AspectModel {

  struct RecordResponse {
    bytes32   hash;
    address   recipient;
    bytes32   generation;
    uint64    timestamp;
    bytes24   details;
    bytes32   content;
    address[] approvers;
  }

  struct GenerationResponse {
    bytes32   id;
    uint64    begin_timestamp;
    uint64    end_timestamp;
    address[] approvers;
  }

  struct ApproverResponse {
    address approver;
    bool    enabled;
  }

  mapping(bytes32 => Generation) generations;
  mapping(address => uint)       approvers_idx;

  event NewGeneration (
    bytes32 id
  );

  event AspectGranted (
    address recipient,
    bytes32 generation,
    bytes24 details,
    bytes32 content,
    bytes   approvers
  );

  constructor(bytes32 t, address owner) AspectModel(t, owner) {}

  function changeOwnership(address new_owner) external onlyOwner {
    setOwner(new_owner);
  }

  function newGeneration(bytes32 id, uint64 begin, uint64 end) external onlyOwner {
    require(generations[id].end_timestamp == 0, "already exists");
    require(end > block.timestamp,              "generation must not be expired");
    insertGeneration(id, Generation({
      begin_timestamp: begin,
      end_timestamp:   end,
      approvers_mask:  approvers_mask,
      records:         new bytes32[](0)
    }));
  }

  function request(
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external {
    Generation storage generation = generations[gen_id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(
      generation.begin_timestamp <= block.timestamp &&
      generation.end_timestamp > block.timestamp,
      "generation inactive"
    );
    insertPendingRecord(Record({
      recipient:  msg.sender,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    }));
  }

  function grant(bytes32 hash) external onlyOwner pendingRecord(hash) {
    Record storage record = pending_records[hash];
    emit AspectGranted(
      record.recipient,
      record.generation,
      record.details,
      record.content,
      record.approvers
    );
    delete pending_records[hash];
  }

  function approve(bytes32 hash) external pendingRecord(hash) {
    Record storage pending_record = pending_records[hash];
    uint idx = approvers_idx[msg.sender];
    require(idx > 0 &&
      generations[pending_record.generation].approvers_mask.getBitStorage(idx - 1),
      "only approver can perform this action");
    pending_record.approvers.setBitStorage(approvers_idx[msg.sender] - 1);
  }

  function clearGeneration(bytes32 gen) external onlyOwner {
    Generation storage generation = generations[gen];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(generation.end_timestamp < block.timestamp, "generation must be expired");
    bytes32[] storage records = generation.records;
    uint len = records.length;
    for (uint n = 0; n < len; n++) delete pending_records[records[n]];
    delete generations[gen].records;
  }

  function enableApprover(address approver) external onlyOwner {
    setApproverState(approver, true);
  }

  function enableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external onlyOwner {
    setGenerationApproverState(approver, gen_id, true);
  }

  function disableApprover(address approver) external onlyOwner {
    setApproverState(approver, false);
  }

  function disableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external onlyOwner {
    setGenerationApproverState(approver, gen_id, false);
  }

  function amIOwner() external view returns(bool) {
    return authorized();
  }

  function getApprovers() external view returns(ApproverResponse[] memory) {
    address[] memory apprs = getApprovers_();
    address[] memory enabled = getApprovers_(getApproversMask_());
    ApproverResponse[] memory res = new ApproverResponse[](apprs.length);
    for (uint n = 0; n < apprs.length; n++) res[n].approver = apprs[n];
    uint stepper = 0;
    for (uint n = 0; n < enabled.length; n++) {
      while (apprs[stepper] != enabled[n]) stepper++;
      res[stepper].enabled = true;
    }
    return res;
  }

  function getGeneration(bytes32 id) external view returns(GenerationResponse memory) {
    Generation memory gen = generations[id];
    GenerationResponse memory res = GenerationResponse({
      id:              id,
      begin_timestamp: gen.begin_timestamp,
      end_timestamp:   gen.end_timestamp,
      approvers:       getApprovers_(gen.approvers_mask)
    });
    return res;
  }

  function getRecordsByGeneration(
    bytes32 gen_id
  ) external view returns(RecordResponse[] memory) {
    bytes32[] memory ids = filterRecordIdsPending_(generations[gen_id].records);
    Record[] memory recs = getPendingRecords_(ids);
    RecordResponse[] memory res = new RecordResponse[](recs.length);
    for (uint n = 0; n < recs.length; n++) {
      res[n].hash = ids[n];
      res[n].recipient = recs[n].recipient;
      res[n].generation = recs[n].generation;
      res[n].timestamp = recs[n].timestamp;
      res[n].details = recs[n].details;
      res[n].content = recs[n].content;
      res[n].approvers = getApprovers_(recs[n].approvers);
    }
    return res;
  }

  function insertGeneration(bytes32 id, Generation memory generation) internal {
    require(generation.begin_timestamp < generation.end_timestamp,
      "ending must be before beginning");
    generations[id] = generation;
    emit NewGeneration(id);
  }

  function insertPendingRecord(Record memory rec) internal {
    bytes32 hash = hashRecord_(rec);
    require(!record_hashes[hash], "already exists");
    pending_records[hash] = rec;
    record_hashes[hash]   = true;
    generations[rec.generation].records.push(hash);
  }

  function setApproverState(address approver, bool enable) internal {
    if (enable) {
      approvers_mask.setBitStorage(getsertApprover(approver));
    } else {
      uint idx = approvers_idx[approver];
      if (idx > 0) {
        approvers_mask.unsetBitStorage(idx - 1);
      }
    }
  }

  function setGenerationApproverState(address approver, bytes32 gen_id, bool enable) internal {
    Generation storage generation = generations[gen_id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(generation.end_timestamp >= block.timestamp, "generation is expired");
    if (enable) {
      generation.approvers_mask.setBitStorage(getsertApprover(approver));
    } else {
      uint idx = approvers_idx[approver];
      if (idx > 0) {
        generation.approvers_mask.unsetBitStorage(idx - 1);
      }
    }
  }

  function getsertApprover(address approver) internal returns(uint) {
    uint idx = approvers_idx[approver];
    if (idx == 0) {
      approvers.push(approver);
      idx = approvers.length;
      approvers_idx[approver] = idx;
    }
    return idx - 1;
  }

  modifier pendingRecord(bytes32 hash) {
    require(record_hashes[hash], "record does not exist");
    Record storage record = pending_records[hash];
    require(record.timestamp != 0, "record not pending");
    Generation storage generation = generations[record.generation];
    require(
      generation.begin_timestamp <= block.timestamp &&
      generation.end_timestamp > block.timestamp,
      "generation inactive"
    );
    _;
  }
}
