// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectApproval is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "1");
  }

  function afterEach() external {
    purgeApprovers();
    purgeGenerations();
  }

  function testApprove() external {
    AspectTestActor[] memory actors = newActors(5);
    setApprovers(actors, 0);
    bytes32 hash = addRecord(pending_records, address(actors[0]), 0, "", "");

    actors[0].approve(hash);
    actors[2].approve(hash);
    actors[4].approve(hash);

    address[] memory approvers = getApprovals(pending_records, hash);
    Assert.equal(approvers.length, 3, "There should be two approvals.");

    Assert.isTrue(
      contains(approvers, address(actors[0])) &&
      contains(approvers, address(actors[2])) &&
      contains(approvers, address(actors[4])),
      "There should be approvals by the correct actors.");
  }

  function testApproveRecordMustBePending() external {
    AspectTestActor[] memory actors = newActors(1);
    setApprovers(actors, 0);
    bytes32 hash = addRecord(records, address(actors[0]), 0, "", "");

    try actors[0].approve(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Pending record does not exist.", what,
        "Should revert with right message.");
    }
  }

  function testApproveMustBeApprover() external {
    AspectTestActor[] memory actors = newActors(1);
    bytes32 hash = addRecord(pending_records, address(actors[0]), 0, "", "");

    try actors[0].approve(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only approver can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testApproveApproverMustBeEnabled() external {
    AspectTestActor[] memory actors = newActors(1);
    addGeneration(block.timestamp, block.timestamp + 10, "2");
    setApprovers(actors, 1);
    bytes32 hash = addRecord(pending_records, address(actors[0]), 0, "", "");

    try actors[0].approve(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only approver can perform this action.", what,
        "Should revert with right message.");
    }
  }
}
