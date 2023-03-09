// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectInternals is BaseTestAspect {

  uint128 constant action_id = 1;

  function testCleaningOldIssues() external {
    aspect.getFirstIssue();
    addPendingAspects(5, block.timestamp - 1 days);
    addPendingAspects(1, block.timestamp + 1 days);
    addPendingAspects(3, block.timestamp - 1 days);

    callRequest(400);
    Assert.equal(aspect.getFirstIssue(), 4, "it should clean 3 motions");
    callRequest(500);
    Assert.equal(aspect.getFirstIssue(), 6, "it should clean 2 motions");
    callRequest(600);
    Assert.equal(aspect.getFirstIssue(), 6, "it should clean 0 motions");
    aspect.removePendingAspect(6);
    callRequest(600);
    Assert.equal(aspect.getFirstIssue(), 9, "it should clean 3 motions");
  }

  function addPendingAspects(uint num, uint deadline) internal {
    for (uint n = 0; n < num; n++) {
      aspect.addPendingAspect(
        address(requester),
        bytes32(uint(1)),
        bytes32(uint(1)),
        deadline
      );
    }
  }

  function callRequest(uint128 issue_id) internal {
    motion_recver.addOpenMotionReturn(issue_id);
    requester.callRequestAspect(aspect, bytes32(uint(1)), bytes32(uint(1)));
  }
}
