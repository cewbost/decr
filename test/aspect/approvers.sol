// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../contracts/Bitset.sol";

using { getBit } for bytes;

contract TestAspectApprovers is AspectTestBase {

  function afterEach() external {
    purgeApprovers();
  }

  function testEnableApprover() external {
    AspectTestActor[] memory actors = newActors(3);
    setOwner(address(actors[0]));

    actors[0].enableApprover(address(actors[1]));
    actors[0].enableApprover(address(actors[2]));

    Assert.equal(approvers.length, 2, "There should be 2 approvers");
    (uint idx1, uint idx2) = (approvers_idx[address(actors[1])], approvers_idx[address(actors[2])]);
    Assert.isTrue(idx1 != 0 && idx2 != 0, "Both approvers should be indexed");
    idx1--; idx2--;
    Assert.isTrue(
      approvers[idx1] == address(actors[1]) &&
      approvers[idx2] == address(actors[2]),
      "Both actors should be added to approvers");
    Assert.isTrue(approvers_mask.getBit(idx1) && approvers_mask.getBit(idx2),
      "Both approvers should be enabled");
  }

  function testReenableApprover() external {
    AspectTestActor[] memory actors = newActors(2);
    setOwner(address(actors[0]));
    approvers.push(address(actors[1]));
    approvers_idx[address(actors[1])] = 1;

    actors[0].enableApprover(address(actors[1]));

    Assert.equal(approvers.length, 1, "There should be 1 approvers");
    Assert.equal(approvers_idx[address(actors[1])], 1, "Approvers index should be unchanged.");
    Assert.isTrue(approvers_mask.getBit(0), "Approver should be enabled.");
  }

  function testEnableApproverOnlyOwner() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].enableApprover(address(actors[1])) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testDisableApprover() external {
    AspectTestActor[] memory actors = newActors(3);
    setOwner(address(actors[0]));

    actors[0].enableApprover(address(actors[1]));
    actors[0].disableApprover(address(actors[1]));

    Assert.equal(approvers.length, 1, "First actor should still be in approvers.");
    uint idx1 = approvers_idx[address(actors[1])];
    Assert.isTrue(idx1 != 0, "Approver should still be indexed.");
    Assert.isFalse(approvers_mask.getBit(idx1 - 1), "Approver should no longer be enabled.");
  }

  function testDisableApproverOnlyOwner() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].disableApprover(address(actors[1])) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }
}
