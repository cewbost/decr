// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MotionSender.sol";
import "./MotionRecver.sol";
import "./Decider.sol";

uint128 constant NEW_ASPECT = 0xDEC2A52E800000000000000000000001;

contract Aspect is MotionSender {

  struct AwardedAspect {
    address recipient;
    bytes32 details;
    bytes32 hash;
    uint    timestamp;
  }

  MotionRecver motion_recver;
  address      decider;

  uint resolving_time;

  uint128 first_issue = 0;
  uint128 last_issue  = 0;

  mapping(uint128 => AwardedAspect)        pending_aspects;
  mapping(uint128 => AwardedAspect) public awarded_aspects;

  uint128 constant cleaning_rate = 3;

  constructor(MotionRecver recver, address decdr, uint res_time) {
    motion_recver  = recver;
    decider        = decdr;
    resolving_time = res_time;
  }

  function requestAspect(bytes32 dets, bytes32 hash) external returns(address, uint) {
    require(dets != 0, "Details cannot be zero.");

    clean();
    last_issue++;
    pending_aspects[last_issue].recipient = msg.sender;
    pending_aspects[last_issue].details   = dets;
    pending_aspects[last_issue].hash      = hash;
    pending_aspects[last_issue].timestamp = block.timestamp + resolving_time;

    uint recverIssue = motion_recver.openMotion(
      msg.sender,
      NEW_ASPECT,
      last_issue,
      decider,
      resolving_time
    );
    return (address(motion_recver), recverIssue);
  }

  function handleResolvedMotion(uint128 issue_id) external override {
    require(msg.sender == address(motion_recver), "Only available to motion handler.");
    AwardedAspect storage aspect = pending_aspects[issue_id];
    require(aspect.timestamp >= block.timestamp, "Pending aspect does not exist.");

    awarded_aspects[issue_id] = aspect;
    awarded_aspects[issue_id].timestamp = block.timestamp;
    delete pending_aspects[issue_id];
  }

  function clean() internal {
    uint128 issue = first_issue;
    uint128 next_issue = first_issue + cleaning_rate;
    if (next_issue >= last_issue) return;
    for (; issue < next_issue; issue++) {
      uint deadline = pending_aspects[issue].timestamp;
      if (deadline < block.timestamp) delete pending_aspects[issue];
      else if (deadline != 0) break;
    }
    first_issue = issue;
  }
}
