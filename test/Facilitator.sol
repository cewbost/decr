// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./utils/contracts/Actor.sol";
import "./utils/contracts/Receiver.sol";
import "./utils/contracts/DecisionPolicy.sol";
import "../contracts/Facilitator.sol";

contract TestFacilitator {

  DecrFacilitator facilitator;
  Actor[]         actors;
  DecisionPolicy  decision_policy;
  Receiver        receiver;

  uint immutable day_before = block.timestamp - 1 days;
  uint immutable day_after  = block.timestamp + 1 days;

  function beforeAll() external {
    facilitator = new DecrFacilitator();
    actors = new Actor[](3);
    for (uint i = 0; i < actors.length; i++) {
      actors[i] = new Actor(facilitator);
    }
    address[] memory signers = new address[](2);
    signers[0] = address(actors[0]);
    signers[1] = address(actors[1]);
    decision_policy = new DecisionPolicy(signers);
  }

  function beforeEach() external {
    receiver = new Receiver(facilitator, decision_policy);
  }

  function testClaiming() external {
    uint128 action_id = 1;
    Actor initiator = new Actor(facilitator);
    (uint128 issue_id, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);
    actors[0].sign(address(receiver), issue_id, slot);
    actors[1].sign(address(receiver), issue_id, slot);
    actors[2].sign(address(receiver), issue_id, slot);

    Assert.isTrue(initiator.claim(address(receiver), issue_id, slot), "claim should succeed");

    Assert.equal(receiver.issues_claimed(), 1, "one claim should have been received");
    Assert.equal(receiver.claimed_issues(0), issue_id, "the claim received should have the correct issue_id");
    (address requester, uint128 claim_action_id) = receiver.claimed_data(issue_id);
    Assert.equal(requester, address(initiator), "the claim received should be for the initiator");
    Assert.equal(claim_action_id, action_id, "the claim received should have the correct action id");
  }

  function testClaimFailWhenNotAllSigned() external {
    uint128 action_id = 1;
    Actor initiator = new Actor(facilitator);
    (uint128 issue_id, uint slot) = initiator.initiate(receiver, action_id, 1 days, 0, 1 days);
    actors[0].sign(address(receiver), issue_id, slot);
    actors[2].sign(address(receiver), issue_id, slot);

    Assert.isFalse(initiator.claim(address(receiver), issue_id, slot), "claim should not succeed");

    Assert.equal(receiver.issues_claimed(), 0, "no claim should have been received");
  }
}
