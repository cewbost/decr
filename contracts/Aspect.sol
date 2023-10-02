// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./shared.sol";

using { shared.getBit, shared.setBit, shared.unsetBit } for bytes;

contract Aspect is Owned {

  string                                name;
  bytes32[]                             generation_ids;
  mapping(bytes32 => shared.Generation) generations;
  mapping(bytes32 => bool)              record_hashes;
  mapping(bytes32 => shared.Record)     pending_records;
  mapping(address => bytes32[])         records_by_recipient;
  address[]                             approvers;
  mapping(address => uint)              approvers_idx;
  bytes                                 approvers_mask;

  event AspectGranted (
    bytes32 generation,
    address recipient
  );

  constructor(string memory n) {
    name = n;
  }

  function request(
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external activeGeneration(gen_id) {
    shared.Record memory rec = shared.Record({
      recipient:  msg.sender,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    addPendingRecord(rec, hashRecord(rec));
  }

  function grant(bytes32 hash) external onlyOwner pendingRecord(hash) {
    shared.Record storage record = pending_records[hash];
    emit AspectGranted(record.generation, record.recipient);
    delete pending_records[hash];
  }

  function approve(bytes32 hash) external pendingRecord(hash) {
    shared.Record storage pending_record = pending_records[hash];
    addApproval(pending_record.generation, hash);
  }

  function newGeneration(
    bytes32 id,
    uint64  begin,
    uint64  end
  ) external onlyOwner uniqueGeneration(id) {
    require(id != "",                           "Generation ID must be provided");
    require(begin < end,                        "Ending must be before beginning");
    shared.Generation storage generation = generations[id];
    generation.begin_timestamp = begin;
    generation.end_timestamp   = end;
    generation.approvers_mask  = approvers_mask;
    generation_ids.push(id);
  }

  function clearGeneration(bytes32 gen) external onlyOwner expiredGeneration(gen) {
    bytes32[] storage records = generations[gen].records;
    uint len = records.length;
    for (uint n = 0; n < len; n++) delete pending_records[records[n]];
    delete generations[gen].records;
  }

  function enableApprover(address approver) external onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx == 0) {
      approvers.push(approver);
      idx = approvers.length - 1;
      approvers_idx[approver] = idx + 1;
    } else {
      idx--;
    }
    approvers_mask.setBit(idx);
  }

  function enableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external notExpiredGeneration(gen_id) onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx == 0) {
      approvers.push(approver);
      idx = approvers.length - 1;
      approvers_idx[approver] = idx + 1;
    } else {
      idx--;
    }
    generations[gen_id].approvers_mask.setBit(idx);
  }

  function disableApprover(address approver) external onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx == 0) return;
    idx--;
    approvers_mask.unsetBit(idx);
  }

  function disableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external notExpiredGeneration(gen_id) onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx == 0) return;
    idx--;
    generations[gen_id].approvers_mask.unsetBit(idx);
  }

  function getApprovers() public view returns(shared.ApproverResponse[] memory) {
    uint num = approvers.length;
    shared.ApproverResponse[] memory res = new shared.ApproverResponse[](num);
    for (uint n = 0; n < num; n++) {
      address approver = approvers[n];
      res[n].approver  = approver;
      res[n].enabled   = approvers_mask.getBit(approvers_idx[approver] - 1);
    }
    return res;
  }

  function getGenerations() public view returns(shared.GenerationResponse[] memory) {
    uint len = generation_ids.length;
    uint alen = approvers.length;
    shared.GenerationResponse[] memory res = new shared.GenerationResponse[](len);
    for (uint n = 0; n < len; n++) {
      bytes32 gen_id = generation_ids[n];
      shared.Generation storage generation = generations[gen_id];
      address[] memory apps = new address[](alen);
      uint acount = 0;
      for (uint a = 0; a < alen; a++) {
        if (generation.approvers_mask.getBit(a)) apps[acount++] = approvers[a];
      }
      address[] memory napps = new address[](acount);
      for (uint a = 0; a < acount; a++) napps[a] = apps[a];
      res[n] = shared.GenerationResponse({
        id:              gen_id,
        begin_timestamp: generation.begin_timestamp,
        end_timestamp:   generation.end_timestamp,
        approvers:       napps
      });
    }
    return res;
  }

  function getPendingRecordsByGeneration(
    bytes32 gen_id
  ) public view generationExists(gen_id) returns(shared.RecordResponse[] memory) {
    return getRecs(generations[gen_id].records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) public view returns(shared.RecordResponse[] memory) {
    return getRecs(records_by_recipient[account]);
  }

  function getRecs(bytes32[] storage recs) internal view returns(shared.RecordResponse[] memory) {
    uint len           = recs.length;
    uint approvers_len = approvers.length;
    uint num_recs      = 0;
    shared.RecordResponse[] memory res              = new shared.RecordResponse[](len);
    address[]               memory approvers_buffer = new address[](approvers_len);
    for (uint n = 0; n < len; n++) {
      bytes32               hash = recs[n];
      shared.Record storage rec  = pending_records[hash];
      if (rec.timestamp != 0) {
        res[num_recs].hash       = hash;
        res[num_recs].recipient  = rec.recipient;
        res[num_recs].generation = rec.generation;
        res[num_recs].timestamp  = rec.timestamp;
        res[num_recs].details    = rec.details;
        res[num_recs].content    = rec.content;
        uint num_approvers = 0;
        for (uint m = 0; m < approvers_len; m++) {
          if (shared.getBit(rec.approvers, m)) {
            approvers_buffer[num_approvers++] = approvers[m];
          }
        }
        res[num_recs].approvers = shared.truncate(approvers_buffer, num_approvers);
        num_recs++;
      }
    }
    return shared.truncate(res, num_recs);
  }

  function hashRecord(shared.Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes32(rec.generation),
      rec.details,
      rec.content
    ));
  }

  function addPendingRecord(shared.Record memory rec, bytes32 hash) internal uniqueRecord(hash) {
    pending_records[hash] = rec;
    generations[rec.generation].records.push(hash);
    records_by_recipient[rec.recipient].push(hash);
    record_hashes[hash] = true;
  }

  function addApproval(bytes32 generation, bytes32 hash) internal onlyApprover(generation) {
    pending_records[hash].approvers.setBit(approvers_idx[msg.sender] - 1);
  }

  modifier pendingRecord(bytes32 hash) {
    require(record_hashes[hash], "Record does not exist");
    shared.Record storage record = pending_records[hash];
    require(record.timestamp != 0, "Record not pending");
    shared.Generation storage generation = generations[record.generation];
    require(
      generation.begin_timestamp <= block.timestamp &&
      generation.end_timestamp > block.timestamp,
      "Generation inactive"
    );
    _;
  }

  modifier activeGeneration(bytes32 id) {
    shared.Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "Generation does not exist");
    require(
      generation.begin_timestamp <= block.timestamp &&
      generation.end_timestamp > block.timestamp,
      "Generation inactive"
    );
    _;
  }

  modifier expiredGeneration(bytes32 id) {
    shared.Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "Generation does not exist");
    require(generation.end_timestamp < block.timestamp, "Generation must be expired");
    _;
  }

  modifier notExpiredGeneration(bytes32 id) {
    shared.Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "Generation does not exist");
    require(generation.end_timestamp > block.timestamp, "Generation is expired");
    _;
  }

  modifier generationExists(bytes32 id) {
    require(generations[id].end_timestamp != 0, "Generation does not exist");
    _;
  }

  modifier uniqueGeneration(bytes32 id) {
    require(generations[id].end_timestamp == 0, "Already exists");
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(!record_hashes[hash], "Already exists");
    _;
  }

  modifier onlyApprover(bytes32 generation) {
    uint approver_idx = approvers_idx[msg.sender];
    require(approver_idx != 0, "Only approver can perform this action");
    require(generations[generation].approvers_mask.getBit(approver_idx - 1),
      "Only approver can perform this action");
    _;
  }
}
