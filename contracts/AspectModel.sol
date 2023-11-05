// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

function getBit(bytes memory bts, uint idx) pure returns(bool) {
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

using { getBit, setBitStorage, unsetBitStorage } for bytes;

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

  mapping(bytes32 => Generation)         generations;
  mapping(bytes32 => bool)               record_hashes;
  mapping(bytes32 => Record)             pending_records;
  address[]                      private approvers;
  mapping(address => uint)               approvers_idx;
  bytes                                  approvers_mask;

  constructor(bytes32 t, address owner) Owned(owner) {
    tag = t;
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

  function setGenerationApproverState_(address approver, bytes32 gen_id, bool enable) internal {
    Generation storage generation = generations[gen_id];
    require(generation.end_timestamp != 0, "generation does not exist");
    require(generation.end_timestamp >= block.timestamp, "generation is expired");
    if (enable) {
      generation.approvers_mask.setBitStorage(getsertApprover_(approver));
    } else {
      uint idx = approvers_idx[approver];
      if (idx > 0) {
        generation.approvers_mask.unsetBitStorage(idx - 1);
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

  function getGeneration_(bytes32 id) internal view returns(Generation memory) {
    return generations[id];
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

  function hashRecord_(Record memory rec) internal pure returns(bytes32) {
    return keccak256(bytes.concat(
      bytes20(rec.recipient),
      bytes32(rec.generation),
      rec.details,
      rec.content
    ));
  }

  modifier uniqueGeneration(bytes32 id) {
    require(generations[id].end_timestamp == 0, "already exists");
    _;
  }

  modifier uniqueRecord(bytes32 hash) {
    require(!record_hashes[hash], "already exists");
    _;
  }
}
