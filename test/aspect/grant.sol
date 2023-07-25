// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../utils/contracts/tools.sol";

contract TestAspectGrant is AspectTestBase, ArrayTools {

  function beforeAll() external {
    addGenerations(block.timestamp, block.timestamp + 10, 1);
  }

  function afterEach() external {
    purgeRecords();
  }

  function testGrant() external {
    AspectTestActor[] memory actors = newActors(2);
    changeOwner(address(actors[0]));
    actors[1].request(0, "details", "content");
    bytes32 hash = generations[0].records[0];

    actors[0].grant(hash);

    Record memory rec = records[hash];
    Assert.equal(address(rec.recipient), address(actors[1]),
      "The record should have the correct recipient.");
    Assert.equal(rec.generation, 0,
      "The record should have the correct generation.");
    Assert.equal(rec.details, "details",
      "The record should have the correct details.");
    Assert.equal(rec.content, "content",
      "The record should have the correct content.");
    Assert.equal(rec.timestamp, block.timestamp,
      "The record should have the correct timestamp.");

    Assert.equal(pending_records[hash].timestamp, 0, "There should be no pending record.");
    Assert.isTrue(contains(generations[0].records, hash),
      "The record should be associated with the generation.");
    Assert.isTrue(contains(records_by_recipient[address(actors[1])], hash),
      "The record should be associated with the recipient.");
  }
}
