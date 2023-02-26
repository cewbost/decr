// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./base.sol";

contract TestFacilitatorClaiming is BaseTestFacilitator {

  function testClaiming() external {
    (uint128 issue_id, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);
    actors[0].sign(slot);
    actors[1].sign(slot);
    actors[2].sign(slot);

    Assert.isTrue(initiator.claim(slot), "Claim should succeed");

    Assert.equal(receiver.issues_claimed(), 1, "One claim should have been received");
    Assert.equal(receiver.claimed_issues(0), issue_id, "The claim received should have the correct issue_id");
    (address requester, uint128 claim_action_id) = receiver.claimed_data(issue_id);
    Assert.equal(requester, address(initiator), "The claim received should be for the initiator");
    Assert.equal(claim_action_id, action_id, "The claim received should have the correct action id");
  }

  function testClaimFailWhenNotAllSigned() external {
    (, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);
    actors[0].sign(slot);
    actors[2].sign(slot);

    Assert.isFalse(initiator.claim(slot), "Claim should not succeed");

    Assert.equal(receiver.issues_claimed(), 0, "No claim should have been received");
  }
}
