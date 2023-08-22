// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Bitset {

  function getBit(bytes storage bts, uint idx) public view returns(bool) {
    return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
  }

  function setBit(bytes storage bts, uint idx) public {
    uint byte_idx = idx / 8;
    bytes1 bit    = toBit(idx % 8);
    uint len      = bts.length;
    if (byte_idx < len) {
      bts[byte_idx] = bts[byte_idx] | bit;
    } else {
      for (; len < byte_idx; len++) bts.push();
      bts.push() = bit;
    }
  }

  function unsetBit(bytes storage bts, uint idx) public {
    uint byte_idx = idx / 8;
    if (byte_idx >= bts.length) return;
    bts[byte_idx] = bts[byte_idx] & ~toBit(idx % 8);
  }

  function toBit(uint bit_idx) public pure returns(bytes1) {
    return bytes1(uint8(1 << bit_idx));
  }

}
