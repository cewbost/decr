// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../utils/contracts/MotionRecver.sol";
import "../utils/contracts/Actor.sol";
import "../../contracts/Aspect.sol";

contract ExposedAspect is Aspect {

  constructor(MotionRecver recver, address decdr, uint res_time) Aspect(recver, decdr, res_time) {}

  function addPendingAspect(
    address rec,
    bytes32 dets,
    bytes32 hash,
    uint ts
  ) public returns(uint128) {
    last_issue++;
    pending_aspects[last_issue].recipient = rec;
    pending_aspects[last_issue].details   = dets;
    pending_aspects[last_issue].hash      = hash;
    pending_aspects[last_issue].timestamp = ts;
    return last_issue;
  }

  function removePendingAspect(uint128 issue) public {
    delete pending_aspects[issue];
  }

  function getFirstIssue() public view returns(uint128) {
    return first_issue;
  }
}

contract BaseTestAspect {

  MockMotionRecver motion_recver;
  Actor            decider;
  Actor            requester;
  ExposedAspect    aspect;

  uint resolving_time;

  function beforeAllBase() external {
    resolving_time = 1 days;
    motion_recver  = new MockMotionRecver();
    decider        = new Actor();
    requester      = new Actor();
    aspect         = new ExposedAspect(motion_recver, address(decider), resolving_time);
  }

  function beforeEachBase() external {
    motion_recver.clear();
  }
}
