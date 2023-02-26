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

  function sign(uint slot) external {
    facilitator.sign(slot);
  }

  function claim(uint slot) external returns (bool) {
    return facilitator.claim(slot);
  }
}
