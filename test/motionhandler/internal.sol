// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestMotionHandlerInternals is BaseTestMotionHandler {

  uint128 constant action_id = 1;

  function testCleaningOldIssues() external {
    handler.getFirstIssue();
    addMotions(5, 100, block.timestamp - 1 days);
    addMotions(1, 200, block.timestamp + 1 days);
    addMotions(3, 300, block.timestamp - 1 days);

    callRequest(400);
    Assert.equal(handler.getFirstIssue(), 4, "it should clean 3 motions");
    callRequest(500);
    Assert.equal(handler.getFirstIssue(), 6, "it should clean 2 motions");
    callRequest(600);
    Assert.equal(handler.getFirstIssue(), 6, "it should clean 0 motions");
    handler.removeMotion(6);
    callRequest(600);
    Assert.equal(handler.getFirstIssue(), 9, "it should clean 3 motions");
  }

  function addMotions(uint num, uint128 first_id, uint deadline) internal {
    for (uint n = 0; n < num; n++) {
      handler.addMotion(
        address(requester),
        action_id,
        first_id + uint128(n),
        address(actors[0]),
        deadline,
        motion_sender
      );
    }
  }

  function callRequest(uint128 issue_id) internal {
    motion_sender.callRequest(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      1 days
    );
  }
}
