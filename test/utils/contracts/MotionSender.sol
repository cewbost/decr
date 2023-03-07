// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionSender.sol";
import "../../../contracts/MotionRecver.sol";

contract MockMotionSender is MotionSender {

  uint128[] public handleResolvedMotionCalls;

  function numHandleResolvedMotionCalls() public view returns(uint) {
    return handleResolvedMotionCalls.length;
  }

  function handleResolvedMotion(uint128 issue_id) external override {
    handleResolvedMotionCalls.push(issue_id);
  }

  function callOpenMotion(
    MotionRecver recver,
    address      requester,
    uint128      action_id,
    uint128      issue_id,
    address      decider,
    uint         resolving_time
  ) external returns(uint) {
    return recver.openMotion(requester, action_id, issue_id, decider, resolving_time);
  }
}
