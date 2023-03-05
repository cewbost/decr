// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestMotionHandlerErrors is BaseTestMotionHandler {

  uint128 constant action_id = 1;
  uint128 constant issue_id  = 0x100;

  function testRequestingFailsWhenTimeInvalid() external {
    try motion_sender.callRequest(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      366 days
    ) returns(uint) {
      Assert.fail("request should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Resolving time too long.", "wrong error");
    }
  }

  function testSigningAndResolvingShouldFailAfterResolve() external {
    uint issue = motion_sender.callRequest(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      1 days
    );
    actors[0].callSign(handler, issue);
    requester.callResolve(handler, issue);

    try actors[0].callSign(handler, issue) {
      Assert.fail("sign should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Motion does not exist.", "wrong error");
    }
    try requester.callResolve(handler, issue) returns(bool) {
      Assert.fail("resolve should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Motion does not exist.", "wrong error");
    }
  }

  function testOnlyRequesterCanResolve() external {
    uint issue = motion_sender.callRequest(
      handler,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      1 days
    );

    try actors[0].callResolve(handler, issue) returns(bool) {
      Assert.fail("resolve should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Unauthorized.", "wrong error");
    }
  }

  function testSigningAndResolvingShouldFailAfterDeadline() external {
    uint issue = 1;
    handler.addMotion(
      issue,
      address(requester),
      action_id,
      issue_id,
      address(actors[0]),
      block.timestamp - 1 days,
      motion_sender
    );

    try actors[0].callSign(handler, issue) {
      Assert.fail("sign should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Motion does not exist.", "wrong error");
    }
    try requester.callResolve(handler, issue) returns(bool) {
      Assert.fail("resolve should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Motion does not exist.", "wrong error");
    }
  }
}
