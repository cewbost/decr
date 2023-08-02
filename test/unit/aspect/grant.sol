// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/Bitset.sol";

using { setBit } for bytes;

contract TestAspectGrant is AspectTestBase {

  function beforeAll() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
  }

  function afterEach() external {
    purgeRecords();
  }

  function testGrant() external {
    AspectTestActor[] memory actors = newActors(2);
    AspectTestActor[] memory approvers = newActors(3);
    setOwner(address(actors[0]));
    setApprovers(approvers, "gen 1");
    bytes32 hash = addRecord(pending_records, address(actors[1]), "gen 1", "details", "content");
    for (uint n = 0; n < 3; n++) pending_records[hash].approvers.setBit(n);

    actors[0].grant(hash);

    Record memory rec = records[hash];
    Assert.equal(address(rec.recipient), address(actors[1]),
      "The record should have the correct recipient.");
    Assert.equal(rec.generation, "gen 1",
      "The record should have the correct generation.");
    Assert.equal(rec.details, "details",
      "The record should have the correct details.");
    Assert.equal(rec.content, "content",
      "The record should have the correct content.");
    Assert.equal(rec.timestamp, block.timestamp,
      "The record should have the correct timestamp.");
    address[] memory approves = getApprovals(records, hash);
    Assert.isTrue(
      approves.length == 3 &&
      contains(approves, address(approvers[0])) &&
      contains(approves, address(approvers[1])) &&
      contains(approves, address(approvers[2])),
      "The record should have all approvals");

    Assert.equal(pending_records[hash].timestamp, 0, "There should be no pending record.");
    Assert.isTrue(contains(generations_idx["gen 1"].records, hash),
      "The record should be associated with the generation.");
    Assert.isTrue(contains(records_by_recipient[address(actors[1])], hash),
      "The record should be associated with the recipient.");
  }

  function testOnlyOwnerAllowed() external {
    AspectTestActor[] memory actors = newActors(2);
    bytes32 hash = addRecord(pending_records, address(actors[1]), "gen 1", "details", "content");

    try actors[0].grant(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function testRecordMustExist() external {
    AspectTestActor[] memory actors = newActors(2);
    setOwner(address(actors[0]));
    bytes32 hash = addRecord(pending_records, address(actors[1]), "gen 1", "details", "content");
    actors[0].grant(hash);

    try actors[0].grant(hash) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Pending record does not exist.", what, "Should revert with right message.");
    }
  }
}
