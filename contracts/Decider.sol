// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface Decider {

  function approveMotion(
    uint128            action_id,
    uint128            issue_id,
    address            requester,
    address[] calldata approvers
  ) external view returns(bool);

  function allowMotion(
    uint128 action_id,
    uint128 issue_id,
    address requester
  ) external view returns(bool);
}
