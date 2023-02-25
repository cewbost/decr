// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {DecrDecisionPolicy} from "./DecisionPolicy.sol";

interface DecrClaimReceiver {
  function receiveClaim(address requester, uint128 action_id, uint128 issue_id) external;
}
