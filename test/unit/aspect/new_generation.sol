// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

using { getBit } for bytes;

contract TestAspectNewGeneration is AspectTestBase {

  bytes32 constant gen_id = "gen id";

  function afterEach() external {
    purgeGenerations();
    purgeApprovers();
  }

  function testNewGenerations() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));

    actor.newGeneration(gen_id, uint64(block.timestamp), uint64(block.timestamp + 10));

    Assert.equal(1, generation_ids.length, "One generation should have been added.");
    Generation storage gen = generations[0];
    Assert.equal(block.timestamp, gen.begin_timestamp,
      "Generation should have correct begin timestamp.");
    Assert.equal(block.timestamp + 10, gen.end_timestamp,
      "Generation should have correct end timestamp.");
    Assert.equal(0, gen.records.length,
      "Generation should have no records.");
  }

  function testNewGenerationApprovers() external {
    AspectTestActor          actor     = newActors(1)[0];
    AspectTestActor[] memory approvers = newActors(5);
    setOwner(address(actor));
    setApprovers(approvers, hex"00_02_04");

    actor.newGeneration(gen_id, uint64(block.timestamp), uint64(block.timestamp + 10));

    Assert.equal(1, generation_ids.length, "A generation should have been added.");
    address[] memory approves = getApprovers(gen_id);
    Assert.isTrue(
      approves.length == 3 &&
      contains(approves, address(approvers[0])) &&
      contains(approves, address(approvers[2])) &&
      contains(approves, address(approvers[4])),
      "The generation should have all enabled approvers");
  }

  function testNewGenerationUniqueId() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    actor.newGeneration(gen_id, uint64(block.timestamp), uint64(block.timestamp + 10));
    try actor.newGeneration(gen_id, uint64(block.timestamp + 10), uint64(block.timestamp + 20)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("ID must be unique.", what, "Should revert with right message.");
    }
  }

  function testNewGenerationValidTimestamps() external {
    AspectTestActor actor = newActors(1)[0];
    setOwner(address(actor));
    try actor.newGeneration(gen_id, uint64(block.timestamp + 10), uint64(block.timestamp)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Ending must be before beginning.", what, "Should revert with right message.");
    }
  }

  function testNewGenerationOnlyOwner() external {
    AspectTestActor actor = newActors(1)[0];
    try actor.newGeneration(gen_id, uint64(block.timestamp + 10), uint64(block.timestamp)) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }

  function getApprovers(bytes32 generation) internal view returns(address[] memory) {
    uint               len   = approvers.length;
    Generation storage gen   = generations[generations_idx[generation] - 1];
    address[]  memory  res   = new address[](len);
    uint               count = 0;
    for (uint n = 0; n < len; n++) if (gen.approvers_mask.getBit(n)) res[count++] = approvers[n];
    return truncate(res, count);
  }
}
