// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "../utils/contracts/MotionRecver.sol";
import "../utils/contracts/Actor.sol";
import "../../contracts/Aspect.sol";

contract TestAspectAwards {

  MockMotionRecver motion_recver;
  Actor            decider;
  Actor            requester;
  Aspect           aspect;

  uint resolving_time;

  function beforeAll() external {
    resolving_time = 1 days;
    motion_recver  = new MockMotionRecver();
    decider        = new Actor();
    requester      = new Actor();
    aspect         = new Aspect(motion_recver, address(decider), resolving_time);
  }

  function beforeEach() external {
    motion_recver.clear();
  }

  function testAward() external {
    uint    recver_issue = 201;
    bytes32 dets         = bytes32(uint(101));
    bytes32 hash         = bytes32(uint(102));
    motion_recver.addOpenMotionReturn(recver_issue);

    (address recver, uint issue) = requester.callRequestAspect(aspect, dets, hash);
    Assert.equal(recver, address(motion_recver), "should return motion receiver");
    Assert.equal(recver_issue, issue,            "should return the correct issue id");

    Assert.equal(motion_recver.numOpenMotionCalls(), 1, "openMotion should be called once");
    ( address reqstr,
      uint128 action_id,
      uint128 sender_issue,
      address decdr,
      uint res_time
    ) = motion_recver.openMotionCalls(0);
    Assert.equal(reqstr, address(requester), "should call requestAspect with the original requester");
    Assert.equal(action_id, NEW_ASPECT,      "should call requestAspect with correct action id");
    Assert.equal(decdr, address(decider),    "should call requestAspect with correct decider");
    Assert.equal(res_time, resolving_time,   "should call requestAspect with correct resolving time");

    motion_recver.callHandleResolvedMotion(aspect, sender_issue);

    ( address recipient,
      bytes32 rec_dets,
      bytes32 rec_hash,
      uint timestamp
    ) = aspect.awarded_aspects(sender_issue);
    Assert.equal(recipient, address(requester), "aspect should be awarded to requester");
    Assert.equal(rec_dets, dets, "aspect should record details");
    Assert.equal(rec_hash, hash, "aspect should record hash");
    Assert.equal(timestamp, block.timestamp, "aspect should record block timestamp");
  }
}
