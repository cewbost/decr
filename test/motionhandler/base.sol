// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../utils/contracts/Actor.sol";
import "../utils/contracts/MotionSender.sol";
import "../../contracts/MotionHandler.sol";

contract ExposedMotionHandler is MotionHandler {

  function addMotion(
    address      requester,
    uint128      action_id,
    uint128      issue_id,
    address      decider,
    uint         deadline,
    MotionSender sendr
  ) public returns(uint) {
    last_issue++;
    Motion storage motion = motions[last_issue];
    motion.requester          = requester;
    motion.action_id          = action_id;
    motion.issue_id           = issue_id;
    motion.decider            = decider;
    motion.resolving_deadline = deadline;
    motion.sendr              = sendr;
    return last_issue;
  }

  function removeMotion(uint issue) public {
    dropMotion(issue);
  }

  function getFirstIssue() public view returns(uint) {
    return first_issue;
  }
}

contract BaseTestMotionHandler {

  ExposedMotionHandler handler;
  Actor[]              actors;
  Actor                requester;
  MockMotionSender     motion_sender;

  function beforeAllBase() external {
    handler = new ExposedMotionHandler();
    actors = new Actor[](3);
    for (uint n = 0; n < actors.length; n++) {
      actors[n] = new Actor();
    }
    requester = new Actor();
  }

  function beforeEachBase() external {
    motion_sender = new MockMotionSender();
  }
}