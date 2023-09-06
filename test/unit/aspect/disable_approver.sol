// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/shared.sol";

using { shared.getBit } for bytes;

contract TestAspectDisableApprover is AspectTestBase {

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
