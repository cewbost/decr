// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./actor.sol";
import "../utils/tools.sol";
import "../../../contracts/Aspect.sol";

using { setBit, getBit } for bytes;

contract AspectTestBase is Aspect, ArrayTools {

  constructor() Aspect("AspectTest") {}

  function newActors(uint num) internal returns(AspectTestActor[] memory) {
    AspectTestActor[] memory actors = new AspectTestActor[](num);
    for (uint n = 0; n < num; n++) actors[n] = new AspectTestActor();
    return actors;
  }

  function addGeneration(uint begin, uint end, bytes32 id) internal {
    generations_idx[id] = generations.length;
    generation_ids.push(id);
    Generation storage gen = generations.push();
    gen.begin_timestamp = uint64(begin);
    gen.end_timestamp   = uint64(end);
  }

  function addRecord(
    mapping(bytes32 => Record) storage map,
    address                            recipient,
    uint32                             generation,
    bytes20                            details,
    bytes32                            content
  ) internal returns(bytes32) {
    Record memory rec = Record({
      recipient:  recipient,
      generation: generation,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    map[hash] = rec;
    generations[generation].records.push(hash);
    records_by_recipient[recipient].push(hash);
    return hash;
  }

  function getRecords(
    bytes32[]                  storage hashes,
    mapping(bytes32 => Record) storage map
  ) internal view returns(Record[] memory) {
    uint            len  = hashes.length;
    uint            num  = 0;
    Record[] memory recs = new Record[](len);
    for (uint n = 0; n < len; n++) {
      Record storage rec = map[hashes[n]];
      if (rec.timestamp != 0) recs[num++] = rec;
    }
    return truncate(recs, num);
  }

  function setApprovers(AspectTestActor[] memory actors) internal {
    for (uint n = 0; n < actors.length; n++) {
      approvers.push(address(actors[n]));
      approvers_idx[address(actors[n])] = n + 1;
    }
  }

  function setApprovers(AspectTestActor[] memory actors, bytes memory enabled) internal {
    setApprovers(actors);
    for (uint n = 0; n < enabled.length; n++) approvers_mask.setBit(uint(uint8(enabled[n])));
  }

  function setApprovers(AspectTestActor[] memory actors, uint generation) internal {
    setApprovers(actors);
    for (uint n = 0; n < actors.length; n++) generations[generation].approvers_mask.setBit(n);
  }

  function getApprovals(
    mapping(bytes32 => Record) storage map,
    bytes32                            hash
  ) internal view returns(address[] memory) {
    uint              len   = approvers.length;
    Record    storage rec   = map[hash];
    address[] memory  res   = new address[](len);
    uint              count = 0;
    for (uint n = 0; n < len; n++) if (rec.approvers.getBit(n)) res[count++] = approvers[n];
    return truncate(res, count);
  }

  function purgeRecords() internal {
    uint gens = generations.length;
    for (uint g = 0; g < gens; g++) {
      bytes32[] storage hashes = generations[g].records;
      uint              recs   = hashes.length;
      for (uint n = 0; n < recs; n++) {
        bytes32 hash = hashes[n];
        delete records_by_recipient[records[hash].recipient];
        delete records[hash];
        delete pending_records[hash];
      }
      delete generations[g].records;
    }
  }

  function purgeGenerations() internal {
    purgeRecords();
    while(generations.length > 0) generations.pop();
    while(generation_ids.length > 0) {
      delete generations_idx[generation_ids[generation_ids.length - 1]];
      generation_ids.pop();
    }
  }

  function purgeApprovers() internal {
    uint len = approvers.length;
    approvers_mask = "";
    for (uint n = 0; n < len; n++) delete approvers_idx[approvers[n]];
    for (uint n = 0; n < len; n++) approvers.pop();
  }
}
