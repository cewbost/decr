// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectClearGeneration is AspectTestBase {

  function testClearGeneration() external {
    AspectTestActor[] memory actors = newActors(2);
    setOwner(address(actors[0]));
    addGeneration(block.timestamp - 20, block.timestamp - 10, "gen 1");
    addGeneration(block.timestamp - 20, block.timestamp - 10, "gen 2");
    bytes32[] memory hashes = new bytes32[](8);
    hashes[0] = addRecord(pending_records, address(actors[1]), "gen 1", "1", "");
    hashes[1] = addRecord(pending_records, address(actors[1]), "gen 2", "2", "");
    hashes[2] = addRecord(pending_records, address(actors[1]), "gen 1", "3", "");
    hashes[3] = addRecord(pending_records, address(actors[1]), "gen 2", "4", "");
    hashes[4] = addRecord(records, address(actors[1]), "gen 1", "5", "");
    hashes[5] = addRecord(records, address(actors[1]), "gen 2", "6", "");
    hashes[6] = addRecord(records, address(actors[1]), "gen 1", "7", "");
    hashes[7] = addRecord(records, address(actors[1]), "gen 2", "8", "");

    actors[0].clearGeneration("gen 1");

    Assert.isTrue(
      pending_records[hashes[0]].timestamp == 0 &&
      pending_records[hashes[2]].timestamp == 0,
      "It should remove the pending records of cleared generation.");
    Assert.isTrue(
      pending_records[hashes[1]].timestamp != 0 &&
      pending_records[hashes[3]].timestamp != 0,
      "It should not remove pending records of other generations.");
    Assert.isTrue(
      records[hashes[4]].timestamp != 0 &&
      records[hashes[6]].timestamp != 0,
      "It should not remove non-pending records of cleared generation.");
    Assert.isTrue(
      records[hashes[5]].timestamp != 0 &&
      records[hashes[7]].timestamp != 0,
      "It should not remove non-pending records of other generations.");

    bytes32[] memory stored = generations["gen 1"].records;
    Assert.isTrue(
      stored.length == 2 &&
      contains(stored, hashes[4]) &&
      contains(stored, hashes[6]),
      "Cleared generation should only have non-pending records left.");
    stored = generations["gen 2"].records;
    Assert.isTrue(
      stored.length == 4 &&
      contains(stored, hashes[1]) &&
      contains(stored, hashes[3]) &&
      contains(stored, hashes[5]) &&
      contains(stored, hashes[7]),
      "Other generations should have all records left.");
    stored = records_by_recipient[address(actors[1])];
    Assert.isTrue(
      stored.length == 6 &&
      contains(stored, hashes[1]) &&
      contains(stored, hashes[3]) &&
      contains(stored, hashes[4]) &&
      contains(stored, hashes[5]) &&
      contains(stored, hashes[6]) &&
      contains(stored, hashes[7]),
      "Cleared records should be removed from user.");
  }
}
