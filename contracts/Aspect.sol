// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./shared.sol";

using { shared.getBit, shared.setBit, shared.unsetBit } for bytes;

contract Aspect is Owned {

  string                                name;
  bytes32[]                             generation_ids;
  mapping(bytes32 => shared.Generation) generations;
  mapping(bytes32 => shared.Record)     records;
  mapping(bytes32 => shared.Record)     pending_records;
  mapping(address => bytes32[])         records_by_recipient;
  address[]                             approvers;
  mapping(address => uint)              approvers_idx;
  bytes                                 approvers_mask;

  constructor(string memory n) {
    name = n;
  }

  function getGenerations() external view returns(shared.GenerationResponse[] memory) {
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
  ) external view generationExists(gen_id) returns(shared.RecordResponse[] memory) {
    return getRecs(generations[gen_id].records, pending_records);
  }

  function getRecordsByGeneration(
    bytes32 gen_id
  ) external view generationExists(gen_id) returns(shared.RecordResponse[] memory) {
    return getRecs(generations[gen_id].records, records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) external view returns(shared.RecordResponse[] memory) {
    return getRecs(records_by_recipient[account], pending_records);
  }

  function getRecordsByRecipient(
    address account
  ) external view returns(shared.RecordResponse[] memory) {
    return getRecs(records_by_recipient[account], records);
  }

  function getRecs(
    bytes32[]                         storage recs,
    mapping(bytes32 => shared.Record) storage recs_map
  ) internal view returns(shared.RecordResponse[] memory) {
    uint len           = recs.length;
    uint approvers_len = approvers.length;
    uint num_recs      = 0;
    shared.RecordResponse[] memory res              = new shared.RecordResponse[](len);
    address[]               memory approvers_buffer = new address[](approvers_len);
    for (uint n = 0; n < len; n++) {
      bytes32               hash = recs[n];
      shared.Record storage rec  = recs_map[hash];
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
    records[hash] = pending_records[hash];
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
    require(id != "",                           "Generation ID must be provided.");
    require(begin < end,                        "Ending must be before beginning.");
    shared.Generation storage generation = generations[id];
    generation.begin_timestamp = begin;
    generation.end_timestamp   = end;
    generation.approvers_mask  = approvers_mask;
    generation_ids.push(id);
  }

  function clearGeneration(bytes32 gen) external onlyOwner inactiveGeneration(gen) {
    shared.Generation storage generation = generations[gen];
    uint               len        = generation.records.length;
    uint[]     memory  idxs       = new uint[](len);
    bytes32[]  memory  hashes     = new bytes32[](len);
    uint               keep       = 0;
    uint               clear      = 0;
    for (uint n = 0; n < len; n++) {
      bytes32 hash = generation.records[n];
      if (pending_records[hash].timestamp == 0) {
        idxs[keep++] = n;
      } else {
        hashes[clear++] = hash;
      }
    }

    for (uint n = 0; n < keep; n++) generation.records[n] = generation.records[idxs[n]];
    for (uint n = keep; n < len; n++) generation.records.pop();

    for (uint n = 0; n < clear; n++) {
      bytes32           hash      = hashes[n];
      address           recipient = pending_records[hash].recipient;
      bytes32[] storage recs      = records_by_recipient[recipient];
      uint              stepper   = 0;
      len = records_by_recipient[recipient].length;
      for (; stepper < len; stepper++) if (recs[stepper] == hash) break;
      for (len--; stepper < len; stepper++) recs[stepper] = recs[stepper + 1];
      recs.pop();
      delete pending_records[hash];
    }
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

  function disableApprover(address approver) external onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx == 0) return;
    idx--;
    approvers_mask.unsetBit(idx);
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
  }

  function addApproval(bytes32 generation, bytes32 hash) internal onlyApprover(generation) {
    pending_records[hash].approvers.setBit(approvers_idx[msg.sender] - 1);
  }

  modifier pendingRecord(bytes32 hash) {
    require(pending_records[hash].timestamp != 0, "Pending record does not exist.");
    _;
  }

  modifier activeGeneration(bytes32 id) {
    require(generations[id].end_timestamp != 0, "Generation does not exist.");
    require(
      generations[id].begin_timestamp <= block.timestamp &&
      generations[id].end_timestamp > block.timestamp,
      "Generation inactive."
    );
    _;
  }

  modifier inactiveGeneration(bytes32 id) {
    require(generations[id].end_timestamp != 0, "Generation does not exist.");
    require(generations[id].end_timestamp < block.timestamp, "Generation must be inactive.");
    _;
  }

  modifier generationExists(bytes32 id) {
    require(generations[id].end_timestamp != 0, "Generation does not exist.");
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(pending_records[hash].timestamp == 0 && records[hash].timestamp == 0,
      "Already exists.");
    _;
  }

  modifier uniqueGeneration(bytes32 id) {
    require(generations[id].end_timestamp == 0, "Already exists.");
    _;
  }

  modifier onlyApprover(bytes32 generation) {
    uint approver_idx = approvers_idx[msg.sender];
    require(approver_idx != 0, "Only approver can perform this action.");
    require(generations[generation].approvers_mask.getBit(approver_idx - 1),
      "Only approver can perform this action.");
    _;
  }
}
