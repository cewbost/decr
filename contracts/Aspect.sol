// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./Shared.sol";

using { Shared.getBit, Shared.setBit, Shared.unsetBit } for bytes;

contract Aspect is Owned {

  string                                name;
  bytes32[]                             generation_ids;
  mapping(bytes32 => Shared.Generation) generations;
  mapping(bytes32 => Shared.Record)     records;
  mapping(bytes32 => Shared.Record)     pending_records;
  mapping(address => bytes32[])         records_by_recipient;
  address[]                             approvers;
  mapping(address => uint)              approvers_idx;
  bytes                                 approvers_mask;

  constructor(string memory n) {
    name = n;
  }

  function getGenerations() external view returns(Shared.GenerationResponse[] memory) {
    uint len = generation_ids.length;
    uint alen = approvers.length;
    Shared.GenerationResponse[] memory res = new Shared.GenerationResponse[](len);
    for (uint n = 0; n < len; n++) {
      bytes32 gen_id = generation_ids[n];
      Shared.Generation storage generation = generations[gen_id];
      address[] memory apps = new address[](alen);
      uint acount = 0;
      for (uint a = 0; a < alen; a++) {
        if (generation.approvers_mask.getBit(a)) apps[acount++] = approvers[a];
      }
      address[] memory napps = new address[](acount);
      for (uint a = 0; a < acount; a++) napps[a] = apps[a];
      res[n] = Shared.GenerationResponse({
        id:              gen_id,
        begin_timestamp: generation.begin_timestamp,
        end_timestamp:   generation.end_timestamp,
        approvers:       napps
      });
    }
    return res;
  }

  function request(
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external activeGeneration(gen_id) {
    Shared.Record memory rec = Shared.Record({
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
    Shared.Record storage pending_record = pending_records[hash];
    addApproval(pending_record.generation, hash);
  }

  function newGeneration(
    bytes32 id,
    uint64  begin,
    uint64  end
  ) external onlyOwner uniqueGeneration(id) {
    require(id != "",                           "Generation ID must be provided.");
    require(begin < end,                        "Ending must be before beginning.");
    Shared.Generation storage generation = generations[id];
    generation.begin_timestamp = begin;
    generation.end_timestamp   = end;
    generation.approvers_mask  = approvers_mask;
    generation_ids.push(id);
  }

  function clearGeneration(bytes32 gen) external onlyOwner inactiveGeneration(gen) {
    Shared.Generation storage generation = generations[gen];
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

  function hashRecord(Shared.Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes4(rec.generation),
      rec.details,
      rec.content
    ));
  }

  function addPendingRecord(Shared.Record memory rec, bytes32 hash) internal uniqueRecord(hash) {
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
