// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./Bitset.sol";

using { getBit, setBit, unsetBit } for bytes;

struct Record {
  address recipient;
  uint32  generation;
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

contract Aspect is Owned {

  string                         name;
  Generation[]                   generations;
  bytes32[]                      generation_ids;
  mapping(bytes32 => uint)       generations_idx;
  mapping(bytes32 => Record)     records;
  mapping(bytes32 => Record)     pending_records;
  mapping(address => bytes32[])  records_by_recipient;
  address[]                      approvers;
  mapping(address => uint)       approvers_idx;
  bytes                          approvers_mask;

  constructor(string memory n) {
    name = n;
  }

  function request(
    uint32  generation,
    bytes20 details,
    bytes32 content
  ) external {
    require(generations.length > generation, "Generation does not exist.");
    require(
      generations[generation].begin_timestamp <= block.timestamp &&
      generations[generation].end_timestamp > block.timestamp,
      "Generation inactive."
    );
    Record memory rec = Record({
      recipient:  msg.sender,
      generation: generation,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    require(pending_records[hash].timestamp == 0 && records[hash].timestamp == 0,
      "Already exists.");
    pending_records[hash] = rec;
    generations[rec.generation].records.push(hash);
    records_by_recipient[rec.recipient].push(hash);
  }

  function grant(bytes32 hash) external onlyOwner pendingRecord(hash) {
    records[hash] = pending_records[hash];
    delete pending_records[hash];
  }

  function approve(bytes32 hash) external pendingRecord(hash) {
    Record storage pending_record = pending_records[hash];
    uint approver_idx = approvers_idx[msg.sender];
    require(approver_idx != 0, "Only approver can perform this action.");
    approver_idx--;
    require(generations[pending_record.generation].approvers_mask.getBit(approver_idx),
      "Only approver can perform this action.");
    pending_records[hash].approvers.setBit(approver_idx);
  }

  function newGeneration(bytes32 id, uint64 begin, uint64 end) external onlyOwner {
    require(id != "",                 "Generation ID must be provided.");
    require(generations_idx[id] == 0, "Generation must not exist.");
    require(begin != 0,               "Beginning must not be zero.");
    require(begin < end,              "Ending must be before beginning.");
    generations_idx[id] = generations.length;
    generation_ids.push(id);
    Generation storage generation = generations.push();
    generation.begin_timestamp = begin;
    generation.end_timestamp   = end;
    generation.approvers_mask  = approvers_mask;
  }

  function clearGeneration(uint32 gen) external onlyOwner {
    require(generations.length > gen, "Generation does not exist.");
    Generation storage generation = generations[gen];
    require(generation.end_timestamp < block.timestamp, "Generation must be inactive.");
    uint             len    = generation.records.length;
    uint[]    memory idxs   = new uint[](len);
    bytes32[] memory hashes = new bytes32[](len);
    uint             keep   = 0;
    uint             clear  = 0;
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

  function hashRecord(Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes4(rec.generation),
      rec.details,
      rec.content
    ));
  }

  modifier pendingRecord(bytes32 hash) {
    require(pending_records[hash].timestamp != 0, "Pending record does not exist.");
    _;
  }
}
