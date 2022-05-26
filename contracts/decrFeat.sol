// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract decrOwned {
  address owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(
      msg.sender == owner,
      "Unauthorized."
    );
    _;
  }
}

contract decrFeat is decrOwned {

  string featName;
  mapping(address => bool) receivers;

  constructor(string memory name) {
    featName = name;
  }

  function award(address recipient) public onlyOwner {
    receivers[recipient] = true;
  }
}
