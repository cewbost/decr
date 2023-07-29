// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/Aspect.sol";

contract AspectTestActor {

  Aspect target;

  constructor() {
    target = Aspect(msg.sender);
  }

  function request(uint32 generation, bytes20 details, bytes32 content) public {
    target.request(generation, details, content);
  }
  function grant(bytes32 hash) public {
    target.grant(hash);
  }
  function newGeneration(uint64 begin, uint64 end) public {
    target.newGeneration(begin, end);
  }
  function clearGeneration(uint32 gen) public {
    target.clearGeneration(gen);
  }
  function enableApprover(address approver) public {
    target.enableApprover(approver);
  }
  function disableApprover(address approver) public {
    target.disableApprover(approver);
  }
}
