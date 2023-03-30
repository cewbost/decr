// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/Aspect.sol";

contract FriendlyAspect is Aspect {

  function getPendingRecords(address receiver) public view returns(Record[] memory) {
    uint[] storage issues = pending_records_index[receiver];
    Record[] memory records = new Record[](issues.length);
    for (uint n = 0; n < issues.length; n++) {
      records[n] = pending_records[issues[n]];
    }
    return records;
  }
}
