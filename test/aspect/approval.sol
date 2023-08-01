// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../utils/contracts/tools.sol";
import "../../contracts/Bitset.sol";

using { getBit, setBit } for bytes;

contract TestAspectApproval is AspectTestBase, ArrayTools {

  function beforeEach() external {
    addGenerations(block.timestamp, block.timestamp + 10, 1);
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

    address[] memory approvers = getApprovals(hash);
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
    addGenerations(block.timestamp, block.timestamp + 10, 1);
    setApprovers(actors, 1);
    bytes32 hash = addRecord(pending_records, address(actors[0]), 0, "", "");

    try actors[0].approve(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only approver can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function setApprovers(AspectTestActor[] memory actors, uint generation) internal {
    for (uint n = 0; n < actors.length; n++) {
      approvers.push(address(actors[n]));
      approvers_idx[address(actors[n])] = n + 1;
      generations[generation].approvers_mask.setBit(n);
    }
  }


  function getApprovals(bytes32 hash) internal view returns(address[] memory) {
    uint              len   = approvers.length;
    Record    storage rec   = pending_records[hash];
    address[] memory  res   = new address[](len);
    uint              count = 0;
    for (uint n = 0; n < len; n++) if (rec.approvers.getBit(n)) res[count++] = approvers[n];
    address[] memory ret = new address[](count);
    for (uint n = 0; n < count; n++) ret[n] = res[n];
    return ret;
  }
}
