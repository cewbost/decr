// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/MotionRecver.sol";
import "../../../contracts/MotionSender.sol";

contract MockMotionRecver is MotionRecver {

  struct RequestCall {
    address requester;
    uint128 action_id;
    uint128 issue_id;
    address decider;
    uint    resolving_time;
  }

  RequestCall[] public openMotionCalls;
  uint[]               open_motion_returns;

  function numOpenMotionCalls() public view returns(uint) {
    return openMotionCalls.length;
  }

  function openMotion(
    address requester,
    uint128 action_id,
    uint128 issue_id,
    address decider,
    uint    resolving_time
  ) external override returns(uint) {
    uint current_call = openMotionCalls.length;
    assert(open_motion_returns.length - current_call > 0);
    RequestCall storage call = openMotionCalls.push();
    call.requester      = requester;
    call.action_id      = action_id;
    call.issue_id       = issue_id;
    call.decider        = decider;
    call.resolving_time = resolving_time;
    return open_motion_returns[current_call];
  }

  function addOpenMotionReturn(uint value) public {
    open_motion_returns.push(value);
  }

  function callHandleResolvedMotion(MotionSender sendr, uint128 issue_id) public {
    sendr.handleResolvedMotion(issue_id);
  }

  function clear() public {
    delete openMotionCalls;
    delete open_motion_returns;
  }
}
