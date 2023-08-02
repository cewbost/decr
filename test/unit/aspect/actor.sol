// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/Aspect.sol";

contract AspectTestActor {

  Aspect target;

  constructor() {
    target = Aspect(msg.sender);
  }

  function request(uint32 generation, bytes20 details, bytes32 content) external {
    target.request(generation, details, content);
  }
  function grant(bytes32 hash) external {
    target.grant(hash);
  }
  function newGeneration(bytes32 id, uint64 begin, uint64 end) external {
    target.newGeneration(id, begin, end);
  }
  function clearGeneration(uint32 gen) external {
    target.clearGeneration(gen);
  }
  function enableApprover(address approver) external {
    target.enableApprover(approver);
  }
  function disableApprover(address approver) external {
    target.disableApprover(approver);
  }
  function approve(bytes32 hash) external {
    target.approve(hash);
  }
}
