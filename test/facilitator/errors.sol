// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestFacilitatorErrors is BaseTestFacilitator {

  function testInitiateFailsWhenTimesInvalid() external {
    try initiator.initiate(receiver, action_id, 1 days, 1 days, 1 days) returns (uint128, uint) {
      Assert.fail("initiate should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Claiming must begin before claiming deadline.", "Reason is incorrect");
    }
    try initiator.initiate(receiver, action_id, 1 days, 0, 366 days) returns (uint128, uint) {
      Assert.fail("initiate should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Claiming time too long.", "Reason is incorrect");
    }
  }

  function testDoubleSigningShouldFail() external {
    (, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);

    actors[0].sign(slot);
    try actors[0].sign(slot) {
      Assert.fail("sign should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Action already signed.", "Reason is incorrect");
    }
  }

  function testSigningAndClaimingShouldFailAfterClaim() external {
    (, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);
    actors[0].sign(slot);
    actors[1].sign(slot);

    Assert.isTrue(initiator.claim(slot), "Claim should succeed");

    try actors[0].sign(slot) {
      Assert.fail("sign should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Action does not exist.", "Reason is incorrect");
    }
    try initiator.claim(slot) returns (bool) {
      Assert.fail("claim should fail");
    } catch Error(string memory reason) {
      Assert.equal(reason, "Action does not exist.", "Reason is incorrect");
    }

    Assert.equal(receiver.issues_claimed(), 1, "One claim should have been received");
  }
}
