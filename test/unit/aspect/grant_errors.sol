// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../../contracts/shared.sol";

using { shared.setBit } for bytes;

contract TestAspectGrantErrors is AspectTestBase {

  function beforeEach() external {
    addGeneration(block.timestamp, block.timestamp + 10, "gen 1");
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
