// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionSender.sol";
import "../../../contracts/MotionRecver.sol";

contract MockMotionSender is MotionSender {

  uint128[] public handleResolvedCalls;

  function numHandleResolvedCalls() public view returns(uint) {
    return handleResolvedCalls.length;
  }

  function handleResolved(uint128 issue_id) external override {
    handleResolvedCalls.push(issue_id);
  }

  function callRequest(
    MotionRecver recver,
    address      requester,
    uint128      action_id,
    uint128      issue_id,
    address      decider,
    uint         resolving_time
  ) external returns(uint) {
    return recver.request(requester, action_id, issue_id, decider, resolving_time);
  }
}
