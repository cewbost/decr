// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface MotionRecver {

  function request(
    address requester,
    uint128 action_id,
    uint128 issue_id,
    address decider,
    uint    resolving_time
  ) external returns(uint);
}
