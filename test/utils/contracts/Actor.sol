// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionHandler.sol";
import "../../../contracts/Aspect.sol";

contract Actor {

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

  function callRequest(Aspect aspect, bytes32 dets, bytes32 hash) public returns(address, uint) {
    return aspect.request(dets, hash);
  }
}
