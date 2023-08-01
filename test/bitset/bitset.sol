// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "../../contracts/Bitset.sol";

using { getBit, setBit, unsetBit } for bytes;

contract TestBitset {

  bytes set;

  function testSet() external {
    set.setBit(0);
    set.setBit(16);
    set.setBit(41);
    set.setBit(43);
    set.setBit(66);
    set.setBit(68);
    set.setBit(70);
    Assert.equal(string(set), hex"01000100000A000054", "should set some bits");
  }

  function testUnset() external {
    bytes memory data = new bytes(4);
    for (uint i = 0; i < data.length; i++) data[i] = 0x0f;
    set = data;
    set.unsetBit(0);
    set.unsetBit(9);
    set.unsetBit(18);
    set.unsetBit(27);
    Assert.equal(string(set), string(hex"0E0D0B07"), "should unset some bits");
  }

  function testGet() external {
    bytes memory data = new bytes(2);
    data[0] = 0x12;
    data[1] = 0x34;
    set     = data;
    Assert.isTrue(set.getBit(1), "should get true");
    Assert.isTrue(set.getBit(4), "should get true");
    Assert.isTrue(set.getBit(10), "should get true");
    Assert.isTrue(set.getBit(12), "should get true");
    Assert.isTrue(set.getBit(13), "should get true");
    Assert.isFalse(set.getBit(0), "should get false");
    Assert.isFalse(set.getBit(2), "should get false");
    Assert.isFalse(set.getBit(3), "should get false");
    Assert.isFalse(set.getBit(5), "should get false");
    Assert.isFalse(set.getBit(6), "should get false");
    Assert.isFalse(set.getBit(7), "should get false");
    Assert.isFalse(set.getBit(8), "should get false");
    Assert.isFalse(set.getBit(9), "should get false");
    Assert.isFalse(set.getBit(11), "should get false");
    Assert.isFalse(set.getBit(14), "should get false");
    Assert.isFalse(set.getBit(15), "should get false");
  }
}
