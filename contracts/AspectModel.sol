// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

contract AspectModel is Owned {

  bytes32 immutable        tag;

  constructor(bytes32 t, address owner) Owned(owner) {
    tag = t;
  }
}
