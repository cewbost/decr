// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MotionRecver.sol";
import "./MotionSender.sol";
import "./Decider.sol";

contract MotionHandler is MotionRecver {

  struct Motion {
    address      requester;
    uint128      action_id;
    uint128      issue_id;
    address      decider;
    uint         resolving_deadline;
    MotionSender sendr;
  }

  mapping(uint => Motion)    motions;
  mapping(uint => address[]) signers;

  uint first_issue = 1;
  uint last_issue  = 0;

  uint constant max_time = 365 days;

  uint constant cleaning_rate = 3;

  function openMotion(
    address requester,
    uint128 action_id,
    uint128 issue_id,
    address decider,
    uint    resolving_time
  ) external override returns(uint) {
    require(resolving_time <= max_time, "Resolving time too long.");

    clean();
    last_issue++;

    Motion storage motion = motions[last_issue];
    motion.requester          = requester;
    motion.action_id          = action_id;
    motion.issue_id           = issue_id;
    motion.decider            = decider;
    motion.resolving_deadline = block.timestamp + resolving_time;
    motion.sendr              = MotionSender(msg.sender);

    return last_issue;
  }

  function sign(uint issue) external {
    Motion storage motion = motions[issue];
    require(motion.resolving_deadline >= block.timestamp, "Motion does not exist.");
    signers[issue].push(msg.sender);
  }

  function resolve(uint issue) external returns(address, uint128) {
    Motion storage motion = motions[issue];
    require(motion.resolving_deadline >= block.timestamp, "Motion does not exist.");
    require(motion.requester == msg.sender, "Unauthorized.");

    if (isApproved(issue, motion)) {
      MotionSender sendr    = motion.sendr;
      uint128      issue_id = motion.issue_id;
      sendr.handleResolvedMotion(issue_id);
      dropMotion(issue);
      return (address(sendr), issue_id);
    } else return (address(uint160(0)), 0);
  }

  function isApproved(uint issue, Motion storage motion) internal view returns(bool) {
    address[] memory signs = uniqueSigners(issue);
    for (uint n = 0; n < signs.length; n++) if (signs[n] == motion.decider) return true;
    try Decider(motion.decider).approveMotion(
      motion.action_id,
      motion.issue_id,
      motion.requester,
      signs
    ) returns (bool res) {
      return res;
    } catch {
      return false;
    }
  }

  function uniqueSigners(uint issue) internal view returns(address[] memory) {
    address[] storage ssigns = signers[issue];
    address[] memory msigns = new address[](ssigns.length);
    uint nsign = 0;
    for (uint n = 0; n < ssigns.length; n++) {
      address addr = ssigns[n];
      uint m = 0;
      for (; m < nsign; m++) {
        if (msigns[m] == addr) break;
      }
      if (m == nsign) {
        msigns[nsign] = addr;
        nsign++;
      }
    }
    if (nsign == msigns.length) return msigns;
    else {
      address[] memory usigns = new address[](nsign);
      for (uint n = 0; n < nsign; n++) {
        usigns[n] = msigns[n];
      }
      return usigns;
    }
  }

  function clean() internal {
    uint issue = first_issue;
    uint next_issue = first_issue + cleaning_rate;
    if (next_issue >= last_issue) return;
    for (; issue < next_issue; issue++) {
      uint deadline = motions[issue].resolving_deadline;
      if (deadline < block.timestamp) dropMotion(issue);
      else if (deadline != 0) break;
    }
    first_issue = issue;
  }

  function dropMotion(uint issue) internal {
    delete motions[issue];
    delete signers[issue];
  }
}
