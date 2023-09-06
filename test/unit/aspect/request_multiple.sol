// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequestMultiple is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
    addGeneration(block.timestamp, block.timestamp + 10, "gen 2");
  }

  function testAddPendingMultipleRecords() external {
    AspectTestActor[] memory actors = newActors(2);
    actors[0].request("gen 1", "1", "");
    actors[0].request("gen 2", "2", "");
    actors[1].request("gen 1", "3", "");
    actors[1].request("gen 2", "4", "");

    address[] memory addrs = new address[](actors.length);
    addrs[0] = address(actors[0]); addrs[1] = address(actors[1]);
    bytes32[] memory details = new bytes32[](2);
    details[0] = "1"; details[1] = "3";
    assertGenerationRecords(getPendingRecordsByGeneration("gen 1"),
      "gen 1", addrs, details,
      "Generation 0 should have the right records.");
    details[0] = "2"; details[1] = "4";
    assertGenerationRecords(getPendingRecordsByGeneration("gen 2"),
      "gen 2", addrs, details,
      "Generation 1 should have the right records.");

    bytes32[] memory gens = new bytes32[](2);
    gens[0] = "gen 1"; gens[1] = "gen 2";
    details[0] = "1"; details[1] = "2";
    assertRecipientRecords(getPendingRecordsByRecipient(addrs[0]),
      addrs[0], gens, details,
      "Actor 0 should have the right records.");
    details[0] = "3"; details[1] = "4";
    assertRecipientRecords(getPendingRecordsByRecipient(addrs[1]),
      addrs[1], gens, details,
      "Actor 1 should have the right records.");
  }

  function assertGenerationRecords(
    shared.RecordResponse[] memory recs,
    bytes32                        gen,
    address[]               memory recvers,
    bytes32[]               memory details,
    string                  memory message
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
    shared.RecordResponse[] memory recs,
    address                        recver,
    bytes32[]               memory generations,
    bytes32[]               memory details,
    string                  memory message
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
