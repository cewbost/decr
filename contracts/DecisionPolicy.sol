// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface DecrDecisionPolicy {
  function approveAction(
    bytes16 actionId,
    address[] calldata approvers
  ) external view returns (bool);
}
