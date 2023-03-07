// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestMotionHandlerResolving is BaseTestMotionHandler {

  uint issue;

  uint128 constant action_id = 1;
  uint128 constant issue_id  = 0x100;

  function beforeEach() external {
    issue = motion_sender.callRequest(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      1 days
    );
  }

  function testResolving() external {
    actors[0].callSign(handler, issue);

    (address sendr, uint128 sendr_id) = requester.callResolve(handler, issue);
    Assert.equal(sendr, address(motion_sender),             "resolve should return the sender contract");
    Assert.equal(sendr_id, issue_id,                        "resolve should return the senders issue id");
    Assert.equal(motion_sender.numHandleResolvedCalls(), 1, "handleResolved should be called once");
    Assert.equal(
      motion_sender.handleResolvedCalls(0),
      issue_id,
      "handleResolved should be called with the correct issue id"
    );
  }

  function testResolvingWithExtraSignatures() external {
    actors[1].callSign(handler, issue);
    actors[0].callSign(handler, issue);
    actors[1].callSign(handler, issue);

    (address sendr, uint128 sendr_id) = requester.callResolve(handler, issue);
    Assert.equal(sendr, address(motion_sender),             "resolve should return the sender contract");
    Assert.equal(sendr_id, issue_id,                        "resolve should return the senders issue id");
    Assert.equal(motion_sender.numHandleResolvedCalls(), 1, "handleResolved should be called once");
    Assert.equal(
      motion_sender.handleResolvedCalls(0),
      issue_id,
      "handleResolved should be called with the correct issue id"
    );
  }

  function testNotResolvingWithWrongSignatures() external {
    actors[1].callSign(handler, issue);
    actors[2].callSign(handler, issue);

    (address sendr, uint128 sendr_id) = requester.callResolve(handler, issue);
    Assert.equal(sendr, address(uint160(0)),                "resolve should return the null contract");
    Assert.equal(sendr_id, 0,                               "resolve should return 0");
    Assert.equal(motion_sender.numHandleResolvedCalls(), 0, "handleResolved should not be called");
  }

  function testNotResolvingWithNoSignatures() external {
    (address sendr, uint128 sendr_id) = requester.callResolve(handler, issue);
    Assert.equal(sendr, address(uint160(0)),                "resolve should return the null contract");
    Assert.equal(sendr_id, 0,                               "resolve should return 0");
    Assert.equal(motion_sender.numHandleResolvedCalls(), 0, "handleResolved should not be called");
  }
}
