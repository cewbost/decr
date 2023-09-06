// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequest is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    addGeneration(block.timestamp, block.timestamp + 10, "gen 2");
  }

  function testAddPendingRecordDetails() external {
    AspectTestActor actor = newActors(1)[0];
    actor.request("gen 1", "details", "content");

    shared.RecordResponse[] memory recs = getPendingRecordsByRecipient(address(actor));
    Assert.equal(recs.length, 1, "There should be on pending record.");
    Assert.equal(address(recs[0].recipient), address(actor),
      "The pending record should have the correct recipient.");
    Assert.equal(recs[0].generation, "gen 1",
      "The pending record should have the correct generation.");
    Assert.equal(recs[0].details, "details",
      "The pending record should have the correct details.");
    Assert.equal(recs[0].content, "content",
      "The pending record should have the correct content.");
    Assert.equal(recs[0].timestamp, block.timestamp,
      "The pending record should have the correct timestamp.");
  }
}
