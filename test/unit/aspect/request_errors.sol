// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequestErrors is AspectTestBase {

  function beforeAll() external {
    addGeneration(block.timestamp, block.timestamp + 10, "1");
    addGeneration(block.timestamp, block.timestamp + 10, "2");
    addGeneration(block.timestamp - 10, block.timestamp - 5, "3");
    addGeneration(block.timestamp + 5, block.timestamp + 10, "4");
  }

  function afterEach() external {
    purgeRecords();
  }

  function testGenerationDoesNotExist() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request(4, "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation does not exist.", what, "Should revert with right message.");
    }
  }

  function testGenerationNotActive() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request(2, "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation inactive.", what, "Should revert with right message.");
    }
  }

  function testGenerationExpired() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.request(3, "", "") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Generation inactive.", what, "Should revert with right message.");
    }
  }

  function testRerequestPending() external {
    AspectTestActor actor = newActors(1)[0];
    actor.request(0, "details", "content");
    try actor.request(0, "details", "content") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Already exists.", what, "Should revert with right message.");
    }
  }

  function testRerequest() external {
    AspectTestActor actor = newActors(1)[0];
    addRecord(records, address(actor), 0, "details", "content");
    try actor.request(0, "details", "content") {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Already exists.", what, "Should revert with right message.");
    }
  }
}
