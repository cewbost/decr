// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Aspect.sol";

contract Console {

  bytes32 immutable        tag;

  mapping(bytes32 => bool) used_tags;

  event AspectCreated(address addr, bytes32 tag);

  constructor(bytes32 t) {
    tag = t;
  }

  function createAspect(bytes32 t) external unusedTag(t) {
    used_tags[t] = true;
    Aspect aspect = new Aspect(t, msg.sender);
    emit AspectCreated(address(aspect), t);
  }

  modifier unusedTag(bytes32 t) {
    require(!used_tags[t], "tag already taken");
    _;
  }
}
