// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/DecisionPolicy.sol";

contract DecisionPolicy is DecrDecisionPolicy {

  address[] members;

  constructor(address[] memory membrs) {
    members = membrs;
  }

  function approveClaim(
    uint128,
    address[] calldata approvers
  ) external view override returns (bool) {
    uint count = 0;
    address[] memory membs = members;
    for (uint i = 0; i < approvers.length; i++) {
      for (uint j = 0; j < membs.length - count; j++) {
        if (approvers[i] == membs[j]) {
          count++;
          membs[j] = membs[membs.length - 1];
          break;
        }
      }
    }
    return count == members.length;
  }
}
