// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

function getBit(bytes memory bts, uint idx) pure returns(bool) {
  return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
}

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

function toBit(uint bit_idx) pure returns(bytes1) {
  return bytes1(uint8(1 << bit_idx));
}

using { getBit, getBitStorage, setBitStorage, unsetBitStorage } for bytes;

contract AspectModel is Owned {

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

  bytes32 immutable                      tag;

  bytes32[]                      private generation_ids;
  mapping(bytes32 => Generation) private generations;
  mapping(bytes32 => bool)       private record_hashes;
  mapping(bytes32 => Record)     private pending_records;
  mapping(address => bytes32[])  private records_by_recipient;
  address[]                      private approvers;
  mapping(address => uint)       private approvers_idx;
  bytes                          private approvers_mask;

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

  function clearGeneration(bytes32 gen) external onlyOwner expiredGeneration(gen) {
    bytes32[] storage records = generations[gen].records;
    uint len = records.length;
    for (uint n = 0; n < len; n++) delete pending_records[records[n]];
    delete generations[gen].records;
  }

  function enableApprover(address approver) external onlyOwner {
    setApproverState_(approver, true);
  }

  function enableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external notExpiredGeneration(gen_id) onlyOwner {
    generations[gen_id].approvers_mask.setBitStorage(getsertApprover_(approver));
  }

  function disableApprover(address approver) external onlyOwner {
    setApproverState_(approver, false);
  }

  function disableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external notExpiredGeneration(gen_id) onlyOwner {
    uint idx = approvers_idx[approver];
    if (idx > 0) {
      generations[gen_id].approvers_mask.unsetBitStorage(idx - 1);
    }
  }

  function insertGeneration_(
    bytes32        id,
    uint64         begin,
    uint64         end,
    bytes   memory mask
  ) internal assertOnlyOwner {
    // Generation id must be unique.
    // Generation must end after beginning.
    // Generation must be listed in generation_ids. TODO remove generation_ids.
    // Generation must not be expired.
    // Generation approvers_mask must not be longer than total approvers list.
    Generation storage generation = generations[id];
    generation.begin_timestamp = begin;
    generation.end_timestamp   = end;
    generation.approvers_mask  = mask;
    generation_ids.push(id);
  }

  function insertPendingRecord_(Record memory rec) internal {
    // Record must not exist.
    // Hash must match record.
    // Generation must be active.
    // Timestamp must be now.
    // Approvers must be empty.
    bytes32 hash = hashRecord_(rec);
    record_hashes[hash]   = true;
    pending_records[hash] = rec;
    generations[rec.generation].records.push(hash);
    records_by_recipient[rec.recipient].push(hash);
  }

  function addApproval(bytes32 generation, bytes32 hash) internal onlyApprover(generation) {
    pending_records[hash].approvers.setBitStorage(approvers_idx[msg.sender] - 1);
  }

  function setApproverState_(address approver, bool enable) internal {
    if (enable) {
      approvers_mask.setBitStorage(getsertApprover_(approver));
    } else {
      uint idx = approvers_idx[approver];
      if (idx > 0) {
        approvers_mask.unsetBitStorage(idx - 1);
      }
    }
  }

  function getsertApprover_(address approver) internal returns(uint) {
    uint idx = approvers_idx[approver];
    if (idx == 0) {
      approvers.push(approver);
      idx = approvers.length;
      approvers_idx[approver] = idx;
    }
    return idx - 1;
  }

  function getGenerations_() internal view returns(bytes32[] memory, Generation[] memory) {
    uint len = generation_ids.length;
    bytes32[]    memory ids  = new bytes32[](len);
    Generation[] memory gens = new Generation[](len);
    for (uint n = 0; n < len; n++) {
      ids[n] = generation_ids[n];
      gens[n] = generations[ids[n]];
    }
    return (ids, gens);
  }

  function getGeneration_(bytes32 id) internal view returns(Generation memory) {
    return generations[id];
  }

  function getRecipientRecordIds_(address recipient) internal view returns(bytes32[] memory) {
    return records_by_recipient[recipient];
  }

  function filterRecordIdsPending_(bytes32[] memory ids) internal view returns(bytes32[] memory) {
    uint keep = 0;
    for (uint n = 0; n < ids.length; n++) {
      if (pending_records[ids[n]].timestamp != 0) ids[keep++] = ids[n];
    }
    bytes32[] memory res = new bytes32[](keep);
    for (uint n = 0; n < keep; n++) res[n] = ids[n];
    return res;
  }

  function getPendingRecords_(bytes32[] memory ids) internal view returns(Record[] memory) {
    Record[] memory recs = new Record[](ids.length);
    for (uint n = 0; n < ids.length; n++) recs[n] = pending_records[ids[n]];
    return recs;
  }

  function getApprovers_() internal view returns(address[] memory) {
    return approvers;
  }

  function getApprovers_(bytes memory mask) internal view returns(address[] memory) {
    uint alen = approvers.length;
    address[] memory apps = new address[](alen);
    uint acount = 0;
    for (uint n = 0; n < alen; n++) if (mask.getBit(n)) apps[acount++] = approvers[n];
    address[] memory res = new address[](acount);
    for (uint n = 0; n < acount; n++) res[n] = apps[n];
    return res;
  }

  function getApproversMask_() internal view returns(bytes memory) {
    return approvers_mask;
  }

  function isNewRecord_(Record memory rec) internal view returns(bool) {
    bytes32 hash = hashRecord_(rec);
    return !record_hashes[hash];
  }

  function hashRecord_(Record memory rec) private pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes32(rec.generation),
      rec.details,
      rec.content
    ));
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

  modifier uniqueGeneration(bytes32 id) {
    require(generations[id].end_timestamp == 0, "already exists");
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(!record_hashes[hash], "already exists");
    _;
  }

  modifier onlyApprover(bytes32 generation) {
    uint idx = approvers_idx[msg.sender];
    require(idx > 0 && generations[generation].approvers_mask.getBitStorage(idx - 1),
      "only approver can perform this action");
    _;
  }

  modifier assertOnlyOwner() virtual {
    assert(authorized());
    _;
  }
}
