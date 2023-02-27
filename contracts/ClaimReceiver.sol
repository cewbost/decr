// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface DecrClaimReceiver {
  function receiveClaim(uint128 action_id, uint128 issue_id) external;
}
