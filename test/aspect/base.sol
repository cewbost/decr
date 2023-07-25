// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./actor.sol";
import "../../contracts/Aspect.sol";

contract AspectTestBase is Aspect {

  function newActors(uint num) internal returns(AspectTestActor[] memory) {
    AspectTestActor[] memory actors = new AspectTestActor[](num);
    for (uint n = 0; n < num; n++) actors[n] = new AspectTestActor();
    return actors;
  }

  function addGenerations(uint begin, uint end, uint n) internal {
    require((begin >> 64) == 0 && (end >> 64) == 0);
    for (; n > 0; n--) {
      Generation storage gen = generations.push();
      gen.begin_timestamp = uint64(begin);
      gen.end_timestamp = uint64(end);
    }
  }

  function addRecord(
    address recipient,
    uint32 generation,
    bytes20 details,
    bytes32 content
  ) internal {
    Record memory rec = Record({
      recipient: recipient,
      generation: generation,
      details: details,
      content: content,
      timestamp: uint64(block.timestamp),
      approvers: ""
    });
    bytes32 hash = hashRecord(rec);
    records[hash] = rec;
    generations[generation].records.push(hash);
    records_by_recipient[recipient].push(hash);
  }

  function getRecords(
    bytes32[]                  storage hashes,
    mapping(bytes32 => Record) storage map
  ) internal view returns(Record[] memory) {
    uint num = hashes.length;
    Record[] memory ret = new Record[](num);
    for (uint n = 0; n < num; n++) {
      ret[n] = map[hashes[n]];
    }
    return ret;
  }

  function purgeRecords() internal {
    uint gens = generations.length;
    for (uint g = 0; g < gens; g++) {
      bytes32[] storage hashes = generations[g].records;
      uint recs = hashes.length;
      for (uint n = 0; n < recs; n++) {
        bytes32 hash = hashes[n];
        delete records_by_recipient[records[hash].recipient];
        delete records[hash];
        delete pending_records[hash];
      }
      delete generations[g].records;
    }
  }
}
