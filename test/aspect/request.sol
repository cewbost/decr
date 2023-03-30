// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./friendly_aspect.sol";
import "../utils/contracts/Actor.sol";
import "../../contracts/Aspect.sol";

contract TestAspectRequest {

  FriendlyAspect aspect;
  Actor          actor;

  function beforeAll() public {
    aspect = new FriendlyAspect();
    actor  = new Actor();
  }

  function testRequestingAspects() public {
    actor.callAspectRequest(aspect, 1, bytes20(uint160(101)), bytes32(uint(201)));
    actor.callAspectRequest(aspect, 2, bytes20(uint160(102)), bytes32(uint(202)));

    Record[] memory records = aspect.getPendingRecords(address(actor));
    Assert.equal(2, records.length, "There should be 3 pending records.");
    assertRecord(records[0], address(actor), 1, bytes20(uint160(101)), bytes32(uint(201)));
    assertRecord(records[1], address(actor), 2, bytes20(uint160(102)), bytes32(uint(202)));
  }

  function testReplacePendingAspectOfGeneration() public {
    actor.callAspectRequest(aspect, 1, bytes20(uint160(101)), bytes32(uint(201)));
    actor.callAspectRequest(aspect, 2, bytes20(uint160(102)), bytes32(uint(202)));
    actor.callAspectRequest(aspect, 3, bytes20(uint160(103)), bytes32(uint(203)));
    actor.callAspectRequest(aspect, 2, bytes20(uint160(104)), bytes32(uint(204)));

    Record[] memory records = aspect.getPendingRecords(address(actor));
    Assert.equal(3, records.length, "There should be 3 pending records.");
    assertRecord(records[0], address(actor), 1, bytes20(uint160(101)), bytes32(uint(201)));
    assertRecord(records[1], address(actor), 2, bytes20(uint160(104)), bytes32(uint(204)));
    assertRecord(records[2], address(actor), 3, bytes20(uint160(103)), bytes32(uint(203)));
  }

  function assertRecord(
    Record  memory record,
    address        recipient,  
    uint32         generation, 
    bytes20        details,    
    bytes32        content     
  ) internal {
    Assert.equal(record.recipient,         recipient,       "The recipient should be correct");
    Assert.equal(record.generation,        generation,      "The generation should be correct");
    Assert.equal(record.timestamp,         block.timestamp, "The timestamp should be correct");
    Assert.equal(record.details,           details,         "The details should be correct");
    Assert.equal(record.content,           content,         "The content should be correct");
    Assert.equal(string(record.approvers), "",              "The approvers should be correct");
  }
}
