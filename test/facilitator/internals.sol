// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "../../contracts/Facilitator.sol";

contract TestFacilitatorInternals is DecrFacilitator {

  function beforeEach() external {
    unusedSlot = 0;
    linkedSlot = type(uint).max;
  }

  function afterEach() external {
    while (actions.length > 0) actions.pop();
    actions.push().next = type(uint).max;
  }

  function testLinkingAndUnliking() external {
    Assert.isTrue(containsElements(linkN(3), [uint(0), 1, 2]), "slots didn't match [0, 1, 2]");
    unlinkSlot(0); unlinkSlot(1);
    Assert.isTrue(containsElements(linkN(3), [uint(0), 1, 3]), "slots didn't match [0, 1, 3]");
    unlinkSlot(1); unlinkSlot(2);
    Assert.isTrue(containsElements(linkN(3), [uint(1), 2, 4]), "slots didn't match [1, 2, 4]");
  }

  function testClean() external {
    linkN(5);
    clean(3);
    Assert.equal(numLinked(), 2, "there should be 2 linked slots left");
  }

  function linkN(uint n) internal returns(uint[] memory) {
    uint[] memory slots = new uint[](n);
    for (uint i = 0; i < n; i++) {
      slots[i] = linkSlot();
    }
    return slots;
  }

  function containsElements(uint[] memory a1, uint[3] memory a2) internal pure returns (bool) {
    for (uint n1 = 0; n1 < a1.length; n1++) {
      bool found = false;
      for (uint n2 = 0; n2 < a2.length; n2++) {
        if (a1[n1] == a2[n2]) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  function numLinked() internal view returns (uint) {
    if (linkedSlot == type(uint).max) return 0;
    uint count = 1;
    uint slot  = linkedSlot;
    while (actions[slot].next != linkedSlot) {
      slot = actions[slot].next;
      count++;
    }
    return count;
  }
}
