// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {

  address private owner;

  constructor(address own) {
    owner = own;
  }

  function setOwner(address new_owner) internal {
    assert(authorized());
    owner = new_owner;
  }

  function authorized() internal view returns(bool) {
    return msg.sender == owner;
  }

  modifier onlyOwner {
    require(authorized(), "only owner can perform this action");
    _;
  }
}
