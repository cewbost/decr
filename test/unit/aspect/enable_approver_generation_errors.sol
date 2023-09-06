// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/shared.sol";

using { shared.getBit } for bytes;

contract TestAspectEnableApproverGenerationErrors is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    addGeneration(block.timestamp - 10, block.timestamp, "gen 2");
  }

  function testEnableApproverOnlyOwner() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].enableApprover(address(actors[1]), "gen 1") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testEnableApproverGenerationMustExist() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].enableApprover(address(actors[1]), "gen 3") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what,
        "Should revert with right message.");
    }
  }

  function testEnableApproverGenerationExpired() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].enableApprover(address(actors[1]), "gen 2") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation is expired.", what,
        "Should revert with right message.");
    }
  }
}
