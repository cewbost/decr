// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../utils/contracts/Decider.sol";

contract TestMotionHandlerApproval is BaseTestMotionHandler {

  MockDecider decider;
  uint        issue;

  uint128 constant action_id = 1;
  uint128 constant issue_id  = 0x100;

  function beforeEach() external {
    decider = new MockDecider();
    issue = motion_sender.callOpenMotion(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(decider),
      1 days
    );
  }

  function testFailApproval() external {
    decider.addApproveMotionCall(action_id + 1, issue_id, address(requester), new address[](0));
    decider.addApproveMotionCall(action_id, issue_id + 1, address(requester), new address[](0));

    Assert.isFalse(requester.callResolveSucceeds(handler, issue), "resolve should fail");
    Assert.equal(
      motion_sender.numHandleResolvedMotionCalls(),
      0,
      "handleResolved should not be called"
    );
  }

  function testApproval() external {
    decider.addApproveMotionCall(action_id, issue_id, address(requester), new address[](0));

    Assert.isTrue(requester.callResolveSucceeds(handler, issue), "resolve should succeed");
    Assert.equal(
      motion_sender.numHandleResolvedMotionCalls(),
      1,
      "handleResolvedMotion should be called once"
    );
  }

  function testApprovalSigners() external {
    address[] memory signers = new address[](2);
    signers[0] = address(actors[0]);
    signers[1] = address(actors[1]);
    decider.addApproveMotionCall(action_id, issue_id, address(requester), signers);

    Assert.isFalse(requester.callResolveSucceeds(handler, issue), "resolve should fail");
    actors[0].callSign(handler, issue);
    Assert.isFalse(requester.callResolveSucceeds(handler, issue), "resolve should fail");
    actors[1].callSign(handler, issue);
    Assert.isTrue(requester.callResolveSucceeds(handler, issue), "resolve should succeed");

    Assert.equal(
      motion_sender.numHandleResolvedMotionCalls(),
      1,
      "handleResolvedMotion should be called once"
    );
  }

  function testApprovalUniqueSigners() external {
    address[] memory signers = new address[](2);
    signers[0] = address(actors[0]);
    signers[1] = address(actors[1]);
    decider.addApproveMotionCall(action_id, issue_id, address(requester), signers);

    actors[0].callSign(handler, issue);
    actors[1].callSign(handler, issue);
    actors[0].callSign(handler, issue);

    Assert.isTrue(requester.callResolveSucceeds(handler, issue), "resolve should succeed");
    Assert.equal(
      motion_sender.numHandleResolvedMotionCalls(),
      1,
      "handleResolvedMotion should be called once"
    );
  }
}
