// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MotionSender.sol";
import "./MotionRecver.sol";
import "./Decider.sol";

contract Aspect is MotionSender {

  struct AwardedAspect {
    address recipient;
    bytes32 dets;
    bytes32 hash;
    uint    timestamp;
  }

  MotionRecver motionRecver;
  address      decider;

  string name;
  uint resolving_time;

  uint128 first_issue = 0;
  uint128 last_issue  = 0;

  mapping(uint128 => AwardedAspect) pending_aspects;
  mapping(uint128 => AwardedAspect) awarded_aspects;

  uint128 constant NEW_ASPECT = 0xDEC2A52E800000000000000000000001;

  uint128 constant cleaning_rate = 3;

  function request(bytes32 dets, bytes32 hash) external returns(address, uint) {
    require(dets != 0);

    clean();
    last_issue++;
    pending_aspects[last_issue].recipient = msg.sender;
    pending_aspects[last_issue].dets      = dets;
    pending_aspects[last_issue].hash      = hash;
    pending_aspects[last_issue].timestamp = block.timestamp + resolving_time;

    uint recverIssue = motionRecver.request(
      msg.sender,
      NEW_ASPECT,
      last_issue,
      decider,
      resolving_time
    );
    return (address(motionRecver), recverIssue);
  }

  function handleResolved(uint128 issue_id) external override {
    require(msg.sender == address(motionRecver));
    AwardedAspect storage aspect = pending_aspects[issue_id];
    require(aspect.timestamp >= block.timestamp);

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
