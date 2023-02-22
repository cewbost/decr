// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {DecrDecisionPolicy} from "./DecisionPolicy.sol";

struct ActionReceived {
  DecrDecisionPolicy decision_policy;
  address            requester;
  bytes16            action_id;
  bytes16            issue_id;
}

interface DecrActionReceiver {
  function takeAction(ActionReceived calldata action) external;
}
