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
  bytes32[] pending_records;
  bytes32[] records;
}

contract Aspect is Owned {

  Generation[]                  generations;
  address[]                     approvers;
  bytes                         approvers_mask;
  mapping(bytes32 => Record)    records;
  mapping(address => bytes32[]) records_by_recipient;
  mapping(bytes32 => Record)    pending_records;
  mapping(address => bytes32[]) pending_records_by_recipient;

  function request(
    uint32 generation,
    bytes20 details,
    bytes32 content
  ) external validGeneration(generation) {
    Record memory rec = Record({
      recipient: msg.sender,
      generation: generation,
      details: details,
      content: content,
      timestamp: uint64(block.timestamp),
      approvers: ""
    });
    bytes32 hash = hashRecord(rec);
    addPendingRecord(hash, rec);
  }

  function addPendingRecord(bytes32 hash, Record memory rec) internal uniqueRecord(hash) {
    pending_records[hash] = rec;
    generations[rec.generation].pending_records.push(hash);
    pending_records_by_recipient[rec.recipient].push(hash);
  }

  function hashRecord(Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes4(rec.generation),
      rec.details,
      rec.content
    ));
  }

  modifier validGeneration(uint32 gen) {
    require(generations.length > gen, "Generation does not exist.");
    require(
      generations[gen].begin_timestamp <= block.timestamp &&
      generations[gen].end_timestamp > block.timestamp,
      "Generation inactive."
    );
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(pending_records[hash].timestamp == 0 && records[hash].timestamp == 0,
      "Already exists.");
    _;
  }
}
