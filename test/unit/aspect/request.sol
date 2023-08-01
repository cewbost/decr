// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequest is AspectTestBase {

  function beforeAll() external {
    addGenerations(block.timestamp, block.timestamp + 10, 2);
    addGenerations(block.timestamp - 10, block.timestamp - 5, 1);
    addGenerations(block.timestamp + 5, block.timestamp + 10, 1);
  }

  function afterEach() external {
    purgeRecords();
  }

  function testAddPendingRecordDetails() external {
    AspectTestActor actor = newActors(1)[0];
    actor.request(0, "details", "content");

    Record[] memory recs = getRecords(generations[0].records, pending_records);
    Assert.equal(recs.length, 1, "There should be on pending record.");
    Assert.equal(address(recs[0].recipient), address(actor),
      "The pending record should have the correct recipient.");
    Assert.equal(recs[0].generation, 0,
      "The pending record should have the correct generation.");
    Assert.equal(recs[0].details, "details",
      "The pending record should have the correct details.");
    Assert.equal(recs[0].content, "content",
      "The pending record should have the correct content.");
    Assert.equal(recs[0].timestamp, block.timestamp,
      "The pending record should have the correct timestamp.");
  }

  function testAddPendingMultipleRecords() external {
    AspectTestActor[] memory actors = newActors(2);
    actors[0].request(0, "1", "");
    actors[0].request(1, "2", "");
    actors[1].request(0, "3", "");
    actors[1].request(1, "4", "");

    address[] memory addrs = new address[](actors.length);
    addrs[0] = address(actors[0]); addrs[1] = address(actors[1]);
    bytes32[] memory details = new bytes32[](2);
    details[0] = "1"; details[1] = "3";
    assertGenerationRecords(getRecords(generations[0].records, pending_records),
      0, addrs, details,
      "Generation 0 should have the right records.");
    details[0] = "2"; details[1] = "4";
    assertGenerationRecords(getRecords(generations[1].records, pending_records),
      1, addrs, details,
      "Generation 1 should have the right records.");

    uint32[] memory gens = new uint32[](2);
    gens[0] = 0; gens[1] = 1;
    details[0] = "1"; details[1] = "2";
    assertRecipientRecords(getRecords(records_by_recipient[addrs[0]], pending_records),
      addrs[0], gens, details,
      "Actor 0 should have the right records.");
    details[0] = "3"; details[1] = "4";
    assertRecipientRecords(getRecords(records_by_recipient[addrs[1]], pending_records),
      addrs[1], gens, details,
      "Actor 1 should have the right records.");
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

  function assertGenerationRecords(
    Record[]  memory recs,
    uint32           gen,
    address[] memory recvers,
    bytes32[] memory details,
    string    memory message
  ) internal {
    for (uint n = 0; n < recs.length; n++) {
      Assert.equal(recs[n].generation, gen,
        string.concat(message, " Invalid generation."));
      Assert.isTrue(contains(recvers, recs[n].recipient),
        string.concat(message, " Invalid recipients."));
      Assert.isTrue(contains(details, recs[n].details),
        string.concat(message, " Invalid details."));
    }
  }

  function assertRecipientRecords(
    Record[]  memory recs,
    address          recver,
    uint32[]  memory generations,
    bytes32[] memory details,
    string    memory message
  ) internal {
    for (uint n = 0; n < recs.length; n++) {
      Assert.equal(recs[n].recipient, recver,
        string.concat(message, " Invalid recipient."));
      Assert.isTrue(contains(generations, recs[n].generation),
        string.concat(message, " Invalid generations."));
      Assert.isTrue(contains(details, recs[n].details),
        string.concat(message, " Invalid details."));
    }
  }
}
