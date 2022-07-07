// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DecrFeat is Ownable {

  string public featName;
  mapping(address => bool) public proposals;
  mapping(address => bool) public recipients;

  constructor(string memory name) {
    featName = name;
  }

  function propose(address recipient) public onlyOwner {
    require(!proposals[recipient] && !recipients[recipient]);
    proposals[recipient] = true;
  }

  function accept() public {
    require(proposals[msg.sender]);
    recipients[msg.sender] = true;
    delete proposals[msg.sender];
  }

  function reject() public {
    require(proposals[msg.sender]);
    delete proposals[msg.sender];
  }
}
