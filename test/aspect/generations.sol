// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectGenerations is AspectTestBase {

  function testNewGeneration() external {
    AspectTestActor actors = newActors(1)[0];

    actors.newGeneration(uint64(block.timestamp), uint64(block.timestamp + 10));
    actors.newGeneration(uint64(block.timestamp + 5), uint64(block.timestamp + 15));

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
    AspectTestActor actors = newActors(1)[0];

    try actors.newGeneration(uint64(block.timestamp + 10), uint64(block.timestamp)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Ending must be before beginning.", what, "Should revert with right message.");
    }
  }
}
