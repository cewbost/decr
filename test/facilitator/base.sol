// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../utils/contracts/Actor.sol";
import "../utils/contracts/Receiver.sol";
import "../utils/contracts/DecisionPolicy.sol";
import "../../contracts/Facilitator.sol";

contract BaseTestFacilitator {

  DecrFacilitator facilitator;
  Actor[]         actors;
  Actor           initiator;
  DecisionPolicy  decision_policy;
  Receiver        receiver;

  uint    immutable day_before = block.timestamp - 1 days;
  uint    immutable day_after  = block.timestamp + 1 days;
  uint128 immutable action_id  = 1;                  

  function beforeAll() external {
    facilitator = new DecrFacilitator();
    actors = new Actor[](3);
    initiator = new Actor(facilitator);
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
}
