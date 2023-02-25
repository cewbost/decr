// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/Facilitator.sol";
import "../../../contracts/ClaimReceiver.sol";
import "../../../contracts/DecisionPolicy.sol";

struct ReceivedData {
  address requester;
  uint128 action_id;
}

contract Receiver is DecrClaimReceiver {

  DecrFacilitator    immutable facilitator;
  DecrDecisionPolicy immutable decision_policy;

  uint128 last_issue_id = 0;

  uint128[]                        public claimed_issues;
  mapping(uint128 => ReceivedData) public claimed_data;

  function issues_claimed() public view returns (uint) {
    return claimed_issues.length;
  }

  constructor(DecrFacilitator fac, DecrDecisionPolicy dec_pol) {
    facilitator     = fac;
    decision_policy = dec_pol;
  }

  function initiate(
    uint128 action_id,
    uint    signing_time,
    uint    claiming_start,
    uint    claiming_time
  ) external returns (uint128, uint) {
    last_issue_id++;
    uint slot = facilitator.initiate(
      msg.sender,
      action_id,
      last_issue_id,
      signing_time,
      claiming_start,
      claiming_time,
      decision_policy
    );
    return (last_issue_id, slot);
  }

  function receiveClaim(address requester, uint128 action_id, uint128 issue_id) external override {
    claimed_issues.push() = issue_id;
    claimed_data[issue_id] = ReceivedData({
      requester: requester,
      action_id: action_id
    });
  }
}
