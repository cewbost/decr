// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectChangeOwnership is AspectTestBase {

  function testChangeOwnership() external {
    AspectTestActor[] memory actors = newActors(2);
    setOwner(address(actors[0]));

    actors[0].changeOwnership(address(actors[1]));
    Assert.equal(owner, address(actors[1]), "should set owner to second actor");
    actors[1].changeOwnership(address(actors[0]));
    Assert.equal(owner, address(actors[0]), "should set owner to first actor");
  }

  function testChangeOwnershipOwnerOnly() external {
    AspectTestActor[] memory actors = newActors(2);
    try actors[0].changeOwnership(address(actors[1])) {
      Assert.fail("Should revert.");
    } catch Error(string memory what) {
      Assert.equal("Only owner can perform this action.", what,
        "Should revert with right message.");
    }
  }
}
