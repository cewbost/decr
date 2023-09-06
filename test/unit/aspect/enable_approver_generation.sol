// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/shared.sol";

using { shared.getBit } for bytes;

contract TestAspectEnableApproverGeneration is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen");
  }

  function testEnableApprover() external {
    AspectTestActor[] memory actors = newActors(3);
    setOwner(address(actors[0]));

    actors[0].enableApprover(address(actors[1]), "gen");
    actors[0].enableApprover(address(actors[2]), "gen");

    Assert.equal(approvers.length, 2, "There should be 2 approvers");
    (uint idx1, uint idx2) = (approvers_idx[address(actors[1])], approvers_idx[address(actors[2])]);
    Assert.isTrue(idx1 != 0 && idx2 != 0, "Both approvers should be indexed");
    idx1--; idx2--;
    Assert.isTrue(
      approvers[idx1] == address(actors[1]) &&
      approvers[idx2] == address(actors[2]),
      "Both actors should be added to approvers");
    bytes storage apprs_mask = generations["gen"].approvers_mask;
    Assert.isTrue(apprs_mask.getBit(idx1) && apprs_mask.getBit(idx2),
      "Both approvers should be enabled");
    Assert.isTrue(!approvers_mask.getBit(idx1) && !approvers_mask.getBit(idx2),
      "Global approvers should not be enabled");
  }

  function testReenableApprover() external {
    AspectTestActor[] memory actors = newActors(2);
    setOwner(address(actors[0]));
    approvers.push(address(actors[1]));
    approvers_idx[address(actors[1])] = 1;

    actors[0].enableApprover(address(actors[1]), "gen");

    Assert.equal(approvers.length, 1, "There should be 1 approvers");
    Assert.equal(approvers_idx[address(actors[1])], 1, "Approvers index should be unchanged.");
    bytes storage apprs_mask = generations["gen"].approvers_mask;
    Assert.isTrue(apprs_mask.getBit(0), "Approver should be enabled.");
  }
}
