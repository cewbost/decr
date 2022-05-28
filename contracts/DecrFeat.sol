// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DecrFeat is Ownable {

  string featName;
  mapping(address => bool) public receivers;

  constructor(string memory name) {
    featName = name;
  }

  function award(address recipient) public onlyOwner {
    receivers[recipient] = true;
  }
}
