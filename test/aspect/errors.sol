// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectErrors is BaseTestAspect {

  function testRequestAspectWithZeroDetsFails() external {
    try requester.callRequestAspect(aspect, 0, bytes32(uint(101))) returns(address, uint) {
      Assert.fail("requestAspect should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Details cannot be zero.", "wrong error");
    }
  }

  function testHandleResolvedMotionFailsWhenNotCalledByRecver() external {
    uint128 sender_issue = openMotion();
    try requester.callHandleResolvedMotion(aspect, sender_issue) {
      Assert.fail("handleResolvedMotion should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Only available to motion handler.", "wrong error");
    }
  }

  function testHandleResolvedMotionFailsWhenMotionDoesNotExist() external {
    try motion_recver.callHandleResolvedMotion(aspect, 0) {
      Assert.fail("handleResolvedMotion should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Pending aspect does not exist.", "wrong error");
    }
  }

  function testHandleResolvedMotionFailsWhenMotionResolved() external {
    uint128 sender_issue = openMotion();
    motion_recver.callHandleResolvedMotion(aspect, sender_issue);
    try motion_recver.callHandleResolvedMotion(aspect, sender_issue) {
      Assert.fail("handleResolvedMotion should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Pending aspect does not exist.", "wrong error");
    }
  }

  function testHandleResolvedMotionFailsAfterDeadline() external {
    uint128 sender_issue = aspect.addPendingAspect(
      address(requester),
      bytes32(uint(101)),
      bytes32(uint(102)),
      block.timestamp - 1 days
    );
    try motion_recver.callHandleResolvedMotion(aspect, sender_issue) {
      Assert.fail("handleResolvedMotion should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Pending aspect does not exist.", "wrong error");
    }
  }

  function openMotion() internal returns(uint128) {
    uint    recver_issue = 201;
    bytes32 dets         = bytes32(uint(101));
    bytes32 hash         = bytes32(uint(102));
    motion_recver.addOpenMotionReturn(recver_issue);
    requester.callRequestAspect(aspect, dets, hash);
    (,, uint128 sender_issue,,) = motion_recver.openMotionCalls(0);
    return sender_issue;
  }
}
