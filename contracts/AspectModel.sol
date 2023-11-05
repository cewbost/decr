// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

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

  constructor(bytes32 t, address owner) Owned(owner) {
    tag = t;
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
