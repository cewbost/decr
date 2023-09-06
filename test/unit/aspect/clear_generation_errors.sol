// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectClearGenerationErrors is AspectTestBase {

  function testClearGenerationOnlyOwner() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.clearGeneration("gen 1") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testClearGenerationMustExist() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    try actor.clearGeneration("gen 1") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what, "Should revert with right message.");
    }
  }

  function testClearGenerationMustBeExpired() external {
    AspectTestActor actor = newActors(1)[0];
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    setOwner(address(actor));
    try actor.clearGeneration("gen 1") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation must be expired.", what, "Should revert with right message.");
    }
  }
}
