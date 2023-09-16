// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/shared.sol";

using { shared.getBit } for bytes;

contract TestAspectDisableApproverGeneration is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    addGeneration(block.timestamp - 10, block.timestamp, "gen 2");
  }

  function testDisableApprover() external {
    AspectTestActor          actor = newActors(1)[0];
    AspectTestActor[] memory apprs = newActors(2);
    setOwner(address(actor));

    addApprovers(apprs);
    approvers_mask = hex"03";
    generations["gen 1"].approvers_mask = hex"03";

    actor.disableApproverForGeneration(address(apprs[1]), "gen 1");

    Assert.equal(approvers.length, 2, "Both actors should still be in approvers.");
    (uint idx0, uint idx1) = (approvers_idx[address(apprs[0])], approvers_idx[address(apprs[1])]);
    Assert.isTrue(idx0 != 0 && idx1 != 0, "Both approvers should still be indexed.");
    bytes storage apprs_mask = generations["gen 1"].approvers_mask;
    Assert.isTrue(apprs_mask.getBit(idx0 - 1),  "First approver should still be enabled.");
    Assert.isFalse(apprs_mask.getBit(idx1 - 1), "Second approver should no longer be enabled.");
  }

  function testDisableApproverOnlyOwner() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].disableApproverForGeneration(address(actors[1]), "gen 1") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testEnableApproverGenerationMustExist() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].disableApproverForGeneration(address(actors[1]), "gen 3") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what,
        "Should revert with right message.");
    }
  }

  function testEnableApproverGenerationExpired() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].disableApproverForGeneration(address(actors[1]), "gen 2") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation is expired.", what,
        "Should revert with right message.");
    }
  }
}
