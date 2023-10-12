// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

function getBit(bytes storage bts, uint idx) view returns(bool) {
  return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
}

function setBit(bytes storage bts, uint idx) {
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

function unsetBit(bytes storage bts, uint idx) {
  uint byte_idx = idx / 8;
  if (byte_idx >= bts.length) return;
  bts[byte_idx] = bts[byte_idx] & ~toBit(idx % 8);
}

function toBit(uint bit_idx) pure returns(bytes1) {
  return bytes1(uint8(1 << bit_idx));
}

using { getBit, setBit, unsetBit } for bytes;

contract Aspect is Owned {

  struct Record {
    address recipient;
    bytes32 generation;
    uint64  timestamp;
    bytes24 details;
    bytes32 content;
    bytes   approvers;
  }

  struct Generation {
    uint64    begin_timestamp;
    uint64    end_timestamp;
    bytes     approvers_mask;
    bytes32[] records;
  }

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

  bytes32 immutable                     tag;

  bytes32[]                             generation_ids;
  mapping(bytes32 => Generation) generations;
  mapping(bytes32 => bool)              record_hashes;
  mapping(bytes32 => Record)     pending_records;
  mapping(address => bytes32[])         records_by_recipient;
  address[]                             approvers;
  mapping(address => uint)              approvers_idx;
  bytes                                 approvers_mask;

  event AspectGranted (
    address recipient,
    bytes32 generation,
    bytes24 details,
    bytes32 content,
    bytes   approvers
  );

  constructor(bytes32 t, address owner) Owned(owner) {
    tag = t;
  }

  function request(
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external activeGeneration(gen_id) {
    Record memory rec = Record({
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
    addApproval(pending_record.generation, hash);
  }

  function newGeneration(
    bytes32 id,
    uint64  begin,
    uint64  end
  ) external onlyOwner uniqueGeneration(id) {
    require(id != "",                           "generation ID must be provided");
    require(begin < end,                        "ending must be before beginning");
    Generation storage generation = generations[id];
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

  function getApprovers() public view returns(ApproverResponse[] memory) {
    uint num = approvers.length;
    ApproverResponse[] memory res = new ApproverResponse[](num);
    for (uint n = 0; n < num; n++) {
      address approver = approvers[n];
      res[n].approver  = approver;
      res[n].enabled   = approvers_mask.getBit(approvers_idx[approver] - 1);
    }
    return res;
  }

  function getGenerations() public view returns(GenerationResponse[] memory) {
    uint len = generation_ids.length;
    uint alen = approvers.length;
    GenerationResponse[] memory res = new GenerationResponse[](len);
    for (uint n = 0; n < len; n++) {
      bytes32 gen_id = generation_ids[n];
      Generation storage generation = generations[gen_id];
      address[] memory apps = new address[](alen);
      uint acount = 0;
      for (uint a = 0; a < alen; a++) {
        if (generation.approvers_mask.getBit(a)) apps[acount++] = approvers[a];
      }
      address[] memory napps = new address[](acount);
      for (uint a = 0; a < acount; a++) napps[a] = apps[a];
      res[n] = GenerationResponse({
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
  ) public view generationExists(gen_id) returns(RecordResponse[] memory) {
    return getRecs(generations[gen_id].records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) public view returns(RecordResponse[] memory) {
    return getRecs(records_by_recipient[account]);
  }

  function getRecs(bytes32[] storage recs) internal view returns(RecordResponse[] memory) {
    uint len           = recs.length;
    uint approvers_len = approvers.length;
    uint num_recs      = 0;
    RecordResponse[] memory res              = new RecordResponse[](len);
    address[]               memory approvers_buffer = new address[](approvers_len);
    for (uint n = 0; n < len; n++) {
      bytes32               hash = recs[n];
      Record storage rec  = pending_records[hash];
      if (rec.timestamp != 0) {
        res[num_recs].hash       = hash;
        res[num_recs].recipient  = rec.recipient;
        res[num_recs].generation = rec.generation;
        res[num_recs].timestamp  = rec.timestamp;
        res[num_recs].details    = rec.details;
        res[num_recs].content    = rec.content;
        uint num_approvers = 0;
        for (uint m = 0; m < approvers_len; m++) {
          if (getBit(rec.approvers, m)) {
            approvers_buffer[num_approvers++] = approvers[m];
          }
        }
        res[num_recs].approvers = truncate(approvers_buffer, num_approvers);
        num_recs++;
      }
    }
    return truncate(res, num_recs);
  }

  function hashRecord(Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes32(rec.generation),
      rec.details,
      rec.content
    ));
  }

  function addPendingRecord(Record memory rec, bytes32 hash) internal uniqueRecord(hash) {
    pending_records[hash] = rec;
    generations[rec.generation].records.push(hash);
    records_by_recipient[rec.recipient].push(hash);
    record_hashes[hash] = true;
  }

  function addApproval(bytes32 generation, bytes32 hash) internal onlyApprover(generation) {
    pending_records[hash].approvers.setBit(approvers_idx[msg.sender] - 1);
  }

  function truncate(address[] memory arr, uint elems) internal pure returns(address[] memory) {
    address[] memory res = new address[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }

  function truncate(
    RecordResponse[] memory arr,
    uint elems
  ) internal pure returns(RecordResponse[] memory) {
    RecordResponse[] memory res = new RecordResponse[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
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

  modifier activeGeneration(bytes32 id) {
    Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(
      generation.begin_timestamp <= block.timestamp &&
      generation.end_timestamp > block.timestamp,
      "generation inactive"
    );
    _;
  }

  modifier expiredGeneration(bytes32 id) {
    Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(generation.end_timestamp < block.timestamp, "generation must be expired");
    _;
  }

  modifier notExpiredGeneration(bytes32 id) {
    Generation storage generation = generations[id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(generation.end_timestamp > block.timestamp, "generation is expired");
    _;
  }

  modifier generationExists(bytes32 id) {
    require(generations[id].end_timestamp != 0, "generation does not exist");
    _;
  }

  modifier uniqueGeneration(bytes32 id) {
    require(generations[id].end_timestamp == 0, "already exists");
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(!record_hashes[hash], "already exists");
    _;
  }

  modifier onlyApprover(bytes32 generation) {
    uint approver_idx = approvers_idx[msg.sender];
    require(approver_idx != 0, "only approver can perform this action");
    require(generations[generation].approvers_mask.getBit(approver_idx - 1),
      "only approver can perform this action");
    _;
  }
}
