// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequestErrors is AspectTestBase {

  function beforeAll() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    addGeneration(block.timestamp, block.timestamp + 10, "gen 2");
    addGeneration(block.timestamp - 10, block.timestamp - 5, "gen 3");
    addGeneration(block.timestamp + 5, block.timestamp + 10, "gen 4");
  }

  function afterEach() external {
    purgeRecords();
  }

  function testGenerationDoesNotExist() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request("gen 5", "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what, "Should revert with right message.");
    }
  }

  function testGenerationNotActive() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request("gen 3", "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation inactive.", what, "Should revert with right message.");
    }
  }

  function testGenerationExpired() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request("gen 4", "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation inactive.", what, "Should revert with right message.");
    }
  }

  function testRerequestPending() external {
    AspectTestActor actor = newActors(1)[0];
    actor.request("gen 1", "details", "content");
    try actor.request("gen 1", "details", "content") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Already exists.", what, "Should revert with right message.");
    }
  }

  function testRerequest() external {
    AspectTestActor actor = newActors(1)[0];
    addRecord(records, address(actor), "gen 1", "details", "content");
    try actor.request("gen 1", "details", "content") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Already exists.", what, "Should revert with right message.");
    }
  }
}
