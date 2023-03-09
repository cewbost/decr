// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionSender.sol";

contract MotionSenderCaller {

  function callHandleResolvedMotion(MotionSender sendr, uint128 issue_id) public {
    sendr.handleResolvedMotion(issue_id);
  }
}
