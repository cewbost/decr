// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

struct Content {
  string granterLink;
  string recipientLink;
  bytes32 contentHash;
  bytes32 details;
}

contract DecrFeat is Ownable {

  string public featName;
  mapping(address => Content) public proposals;
  mapping(address => Content) public recipients;

  constructor(string memory name) {
    featName = name;
  }

  function propose(address recipient, string calldata link, bytes32 hash, bytes32 dets) public onlyOwner {
    require(dets != 0);
    require(proposals[recipient].details == 0 && recipients[recipient].details == 0);
    proposals[recipient] = Content({
      granterLink:    link,
      recipientLink:  "",
      contentHash:    hash,
      details:        dets
    });
  }

  function accept(string calldata link) public {
    require(proposals[msg.sender].details != 0);
    recipients[msg.sender] = proposals[msg.sender];
    recipients[msg.sender].recipientLink = link;
    delete proposals[msg.sender];
  }

  function reject() public {
    require(proposals[msg.sender].details != 0);
    delete proposals[msg.sender];
  }
  
  function setRecipientLink(string calldata link) public {
    require(recipients[msg.sender].details != 0);
    recipients[msg.sender].recipientLink = link;
  }
}
