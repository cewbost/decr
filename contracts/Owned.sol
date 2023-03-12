// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {

  address owner;

  constructor() {
    owner = msg.sender;
  }

  function authorized() public view {
    require(msg.sender == owner, "Only owner can perform this action.");
  }

  modifier onlyOwner {
    authorized();
    _;
  }

  function changeOwner(address new_owner) public onlyOwner {
    owner = new_owner;
  }
}
