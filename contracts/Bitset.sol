// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct bitset {
  bytes data;
}

library Bitset {

  function get(bitset storage bts, uint idx) public view returns(bool) {
    bytes storage bs = bts.data;
    return (bs[idx/8] & toBit(idx % 8)) != 0;
  }

  function set(bitset storage bts, uint idx) public {
    bytes storage bs = bts.data;
    uint byte_idx = idx / 8;
    bytes1 bit = toBit(idx % 8);
    uint len = bs.length;
    if (byte_idx < len) {
      bs[byte_idx] = bs[byte_idx] | bit;
    } else {
      bytes memory mbs = new bytes(byte_idx + 1 - len);
      mbs[mbs.length - 1] = bit;
      bts.data = bytes.concat(bs, mbs);
    }
  }

  function unset(bitset storage bts, uint idx) public {
    bytes storage bs = bts.data;
    uint byte_idx = idx / 8;
    if (byte_idx >= bs.length) return;
    bs[byte_idx] = bs[byte_idx] & ~toBit(idx % 8);
  }

  function toBit(uint bit_idx) internal pure returns(bytes1) {
    return bytes1(uint8(1 << bit_idx));
  }
}
