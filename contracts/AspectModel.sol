// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

function getBit(bytes memory bts, uint idx) pure returns(bool) {
  return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
}

function toBit(uint bit_idx) pure returns(bytes1) {
  return bytes1(uint8(1 << bit_idx));
}

using { getBit } for bytes;

contract AspectModel is Owned {

  struct Record {
    address recipient;
    bytes32 generation;
    uint64  timestamp;
    bytes24 details;
    bytes32 content;
    bytes   approvers;
  }

  bytes32 immutable        tag;

  mapping(bytes32 => bool) record_hashes;
  bytes                    approvers_mask;

  constructor(bytes32 t, address owner) Owned(owner) {
    tag = t;
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

  modifier uniqueRecord(bytes32 hash) {
    require(!record_hashes[hash], "already exists");
    _;
  }
}
