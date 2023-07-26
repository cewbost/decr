// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectGenerations is AspectTestBase {

  function afterEach() external {
    purgeGenerations();
  }

  function testNewGeneration() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));

    actor.newGeneration(uint64(block.timestamp), uint64(block.timestamp + 10));
    actor.newGeneration(uint64(block.timestamp + 5), uint64(block.timestamp + 15));

    Assert.equal(2, generations.length, "Two generations should have been added.");
    Assert.equal(block.timestamp, generations[0].begin_timestamp,
      "First generation should have correct begin timestamp.");
    Assert.equal(block.timestamp + 10, generations[0].end_timestamp,
      "First generation should have correct end timestamp.");
    Assert.equal(0, generations[0].records.length,
      "First generation should have no records.");
    Assert.equal(block.timestamp + 5, generations[1].begin_timestamp,
      "Second generation should have correct begin timestamp.");
    Assert.equal(block.timestamp + 15, generations[1].end_timestamp,
      "Second generation should have correct end timestamp.");
    Assert.equal(0, generations[1].records.length,
      "Second generation should have no records.");
  }

  function testNewGenerationValidTimestamps() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    try actor.newGeneration(uint64(block.timestamp + 10), uint64(block.timestamp)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Ending must be before beginning.", what, "Should revert with right message.");
    }
  }

  function testNewGenerationOnlyOwner() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.newGeneration(uint64(block.timestamp + 10), uint64(block.timestamp)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testClearGeneration() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    addGenerations(block.timestamp - 20, block.timestamp - 10, 1);
  }

  function testClearGenerationOnlyOwner() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.clearGeneration(0) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testGenerationMustExist() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    try actor.clearGeneration(0) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what, "Should revert with right message.");
    }
  }

  function testGenerationMustBeInactive() external {
    AspectTestActor actor = newActors(1)[0];
    addGenerations(block.timestamp, block.timestamp + 10, 1);
    setOwner(address(actor));
    try actor.clearGeneration(0) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation must be inactive.", what, "Should revert with right message.");
    }
  }
}
