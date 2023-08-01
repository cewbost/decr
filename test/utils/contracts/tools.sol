// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../../contracts/Aspect.sol";

contract ArrayTools {

  function contains(uint32[] memory arr, uint32 elem) internal pure returns(bool) {
    for (uint n = 0; n < arr.length; n++) if (arr[n] == elem) return true;
    return false;
  }

  function contains(bytes32[] memory arr, bytes32 elem) internal pure returns(bool) {
    for (uint n = 0; n < arr.length; n++) if (arr[n] == elem) return true;
    return false;
  }

  function contains(address[] memory arr, address elem) internal pure returns(bool) {
    for (uint n = 0; n < arr.length; n++) if (arr[n] == elem) return true;
    return false;
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
}
