// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../utils/contracts/Actor.sol";
import "../utils/contracts/MotionSender.sol";
import "../../contracts/MotionHandler.sol";

contract BaseTestMotionHandler {

  MotionHandler    handler;
  Actor[]          actors;
  Actor            requester;
  MockMotionSender motion_sender;

  function beforeAll() external {
    handler = new MotionHandler();
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
