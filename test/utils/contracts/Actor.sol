// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/Facilitator.sol";
import "./Receiver.sol";

contract Actor {

  DecrFacilitator immutable facilitator;

  constructor(DecrFacilitator fac) {
    facilitator     = fac;
  }

  function initiate(
    Receiver recver,
    uint128  action_id,
    uint     signing_time,
    uint     claiming_start,
    uint     claiming_time
  ) external returns (uint128, uint) {
    return recver.initiate(action_id, signing_time, claiming_start, claiming_time);
  }

  function sign(address receiver, uint128 issue_id, uint slot) external {
    facilitator.sign(receiver, issue_id, slot);
  }

  function claim(address receiver, uint128 issue_id, uint slot) external returns (bool) {
    return facilitator.claim(receiver, issue_id, slot);
  }
}
