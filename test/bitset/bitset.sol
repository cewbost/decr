// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "../../contracts/Bitset.sol";

using Bitset for bitset;

contract TestBitset {

  bitset set;

  function testSet() external {
    set.set(0);
    set.set(16);
    set.set(41);
    set.set(43);
    set.set(66);
    set.set(68);
    set.set(70);
    Assert.equal(string(set.data), hex"01000100000A000054", "should set some bits");
  }

  function testUnset() external {
    bytes memory data = new bytes(4);
    for (uint i = 0; i < data.length; i++) data[i] = 0x0f;
    set.data = data;
    set.unset(0);
    set.unset(9);
    set.unset(18);
    set.unset(27);
    Assert.equal(string(set.data), string(hex"0E0D0B07"), "should unset some bits");
  }

  function testGet() external {
    bytes memory data = new bytes(2);
    data[0] = 0x12;
    data[1] = 0x34;
    set.data = data;
    Assert.isTrue(set.get(1), "should get true");
    Assert.isTrue(set.get(4), "should get true");
    Assert.isTrue(set.get(10), "should get true");
    Assert.isTrue(set.get(12), "should get true");
    Assert.isTrue(set.get(13), "should get true");
    Assert.isFalse(set.get(0), "should get false");
    Assert.isFalse(set.get(2), "should get false");
    Assert.isFalse(set.get(3), "should get false");
    Assert.isFalse(set.get(5), "should get false");
    Assert.isFalse(set.get(6), "should get false");
    Assert.isFalse(set.get(7), "should get false");
    Assert.isFalse(set.get(8), "should get false");
    Assert.isFalse(set.get(9), "should get false");
    Assert.isFalse(set.get(11), "should get false");
    Assert.isFalse(set.get(14), "should get false");
    Assert.isFalse(set.get(15), "should get false");
  }
}
