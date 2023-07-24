// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ArrayTools {

  function sort(bytes32[] memory arr) internal pure {
    for (uint n = arr.length - 1; n >= 0; n--) {
      bytes32 elem = arr[n];
      uint m = n;
      for (; m < arr.length - 1; m++) {
        if (elem <= arr[m + 1]) break;
        arr[m] = arr[m + 1];
      }
      arr[m] = elem;
    }
  }
}
