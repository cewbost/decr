// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionHandler.sol";

contract Actor {

  function callSign(MotionHandler handler, uint issue) external {
    handler.sign(issue);
  }

  function callResolve(MotionHandler handler, uint issue) external returns(bool) {
    return handler.resolve(issue);
  }
}
