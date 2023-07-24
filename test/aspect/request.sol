// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../utils/contracts/tools.sol";

contract TestAspectRequest is AspectTestBase, ArrayTools {

  function beforeAll() external {
    addGenerations(block.timestamp, block.timestamp + 1, 1);
  }

  function afterEach() external {
    purgePendingRecords();
  }

  function testAddPendingRecordDetails() external {
    addGenerations(block.timestamp, block.timestamp + 1, 1);
    AspectTestActor actor = newActors(1)[0];

    actor.request(0, "details", "content");

    Record[] memory recs = getPendingRecordsByGeneration(0);
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

  function getPendingRecordsByGeneration(uint32 gen) internal view returns(Record[] memory) {
    bytes32[] storage hashes = generations[gen].pending_records;
    uint num = hashes.length;
    Record[] memory ret = new Record[](num);
    for (uint n = 0; n < num; n++) {
      ret[n] = pending_records[hashes[n]];
    }
    return ret;
  }
}
