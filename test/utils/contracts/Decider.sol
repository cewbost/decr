// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "../../../contracts/Decider.sol";

contract MockDecider is Decider {

  struct ApproveMotionCall {
    uint128   action_id;
    address   requester;
    address[] approvers;
  }

  mapping(uint128 => ApproveMotionCall) expected_approve_motion_calls;

  function approveMotion(
    uint128            action_id,
    uint128            issue_id,
    address            requester,
    address[] calldata approvers
  ) external view override returns(bool) {
    ApproveMotionCall storage call = expected_approve_motion_calls[issue_id];
    if (call.action_id != action_id) return false;
    if (call.requester != requester) return false;
    address[] memory ex_approvers = call.approvers;
    if (ex_approvers.length != approvers.length) return false;
    for (uint n = 0; n < approvers.length; n++) {
      bool found = false;
      for (uint m = 0; m < ex_approvers.length - n; m++) {
        if (approvers[n] == ex_approvers[m]) {
          ex_approvers[m] = ex_approvers[ex_approvers.length - n - 1];
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  function addApproveMotionCall(
    uint128            action_id,
    uint128            issue_id,
    address            requester,
    address[] calldata approvers
  ) external {
    ApproveMotionCall storage call = expected_approve_motion_calls[issue_id];
    call.action_id = action_id;
    call.requester = requester;
    call.approvers = approvers;
  }

  function allowMotion(
    uint128,
    uint128,
    address
  ) external pure override returns(bool) {
    revert("not implemented");
  }
}
