// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {

  address owner;

  constructor(address own) {
    owner = own;
  }

  function authorized() public view {
    require(msg.sender == owner, "only owner can perform this action");
  }

  modifier onlyOwner {
    authorized();
    _;
  }

  function changeOwnership(address new_owner) public onlyOwner {
    setOwner(new_owner);
  }

  function setOwner(address new_owner) internal {
    owner = new_owner;
  }
}
