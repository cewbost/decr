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

  RequestCall[] public request_calls;
  uint[]               request_returns;

  function numRequestCalls() public view returns(uint) {
    return request_calls.length;
  }

  function request(
    address requester,
    uint128 action_id,
    uint128 issue_id,
    address decider,
    uint    resolving_time
  ) external override returns(uint) {
    uint current_call = request_calls.length;
    assert(request_returns.length - current_call > 0);
    RequestCall storage call = request_calls.push();
    call.requester      = requester;
    call.action_id      = action_id;
    call.issue_id       = issue_id;
    call.decider        = decider;
    call.resolving_time = resolving_time;
    return request_returns[current_call];
  }

  function addRequestReturn(uint value) public {
    request_returns.push(value);
  }

  function callHandleResolved(MotionSender sendr, uint128 issue_id) public {
    sendr.handleResolved(issue_id);
  }

  function clear() public {
    delete request_calls;
    delete request_returns;
  }
}
