// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MotionSenderCaller.sol";
import "../../../contracts/MotionHandler.sol";
import "../../../contracts/OldAspect.sol";
import "../../../contracts/OldAspect2.sol";
import "../../../contracts/Aspect.sol";

contract Actor is MotionSenderCaller {

  function callSign(MotionHandler handler, uint issue) public {
    handler.sign(issue);
  }

  function callResolve(MotionHandler handler, uint issue) public returns(address, uint128) {
    return handler.resolve(issue);
  }

  function callResolveSucceeds(MotionHandler handler, uint issue) public returns(bool) {
    (, uint128 issue_id) = callResolve(handler, issue);
    return issue_id != 0;
  }

  function callRequestAspect(
    OldAspect aspect,
    bytes32 dets,
    bytes32 hash
  ) public returns(address, uint) {
    return aspect.requestAspect(dets, hash);
  }

  function callAspectRequest(
    OldAspect2 aspect,
    uint32     generation,
    bytes20    details,
    bytes32    content
  ) public {
    aspect.request(generation, details, content);
  }
}
