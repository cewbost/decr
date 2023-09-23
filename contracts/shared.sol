// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library shared {

  struct Record {
    address recipient;
    bytes32 generation;
    uint64  timestamp;
    bytes24 details;
    bytes32 content;
    bytes   approvers;
  }

  struct Generation {
    uint64    begin_timestamp;
    uint64    end_timestamp;
    bytes     approvers_mask;
    bytes32[] records;
  }

  struct RecordResponse {
    bytes32   hash;
    address   recipient;
    bytes32   generation;
    uint64    timestamp;
    bytes24   details;
    bytes32   content;
    address[] approvers;
  }

  struct GenerationResponse {
    bytes32   id;
    uint64    begin_timestamp;
    uint64    end_timestamp;
    address[] approvers;
  }

  struct ApproverResponse {
    address approver;
    bool    enabled;
  }

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

  function truncate(address[] memory arr, uint elems) internal pure returns(address[] memory) {
    address[] memory res = new address[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }

  function truncate(Record[] memory arr, uint elems) internal pure returns(Record[] memory) {
    Record[] memory res = new Record[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }

  function truncate(
    RecordResponse[] memory arr,
    uint elems
  ) internal pure returns(RecordResponse[] memory) {
    RecordResponse[] memory res = new RecordResponse[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }

}
