// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {DecrDecisionPolicy} from "./DecisionPolicy.sol";

contract DecrTresholdPolicy is DecrDecisionPolicy {
  
  address[] members;
  uint immutable tres_dividend;
  uint immutable tres_divisor;
  
  constructor(address[] memory membs, uint dividend, uint divisor) {
    members = membs;
    tres_dividend = dividend;
    tres_divisor = divisor;
  }
  
  function approveAction(
    bytes16,
    address[] calldata approvers
  ) external view override returns (bool) {
    require(approvers.length > 0);
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
    return count * tres_divisor > members.length * tres_divisor;
  }
}
