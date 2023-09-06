// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./actor.sol";
import "../utils/tools.sol";
import "../../../contracts/Aspect.sol";

using { shared.setBit, shared.getBit } for bytes;

contract AspectTestBase is Aspect, ArrayTools {

  constructor() Aspect("AspectTest") {}

  function afterEachBase() external {
    uint gens = generation_ids.length;
    for (uint g = gens; g > 0; g--) {
      bytes32 gen_id = generation_ids[g - 1];
      shared.Generation storage generation = generations[gen_id];
      bytes32[] storage hashes = generation.records;
      uint              recs   = hashes.length;
      for (uint n = 0; n < recs; n++) {
        bytes32 hash = hashes[n];
        delete records_by_recipient[records[hash].recipient];
        delete records[hash];
        delete pending_records[hash];
      }
      delete generations[gen_id];
      generation_ids.pop();
    }
    uint len = approvers.length;
    approvers_mask = "";
    for (uint n = 1; n <= len; n++) {
      delete approvers_idx[approvers[len - n]];
      approvers.pop();
    }
  }

  function newActors(uint num) internal returns(AspectTestActor[] memory) {
    AspectTestActor[] memory actors = new AspectTestActor[](num);
    for (uint n = 0; n < num; n++) actors[n] = new AspectTestActor();
    return actors;
  }

  function addGeneration(uint begin, uint end, bytes32 id) internal {
    shared.Generation storage gen = generations[id];
    gen.begin_timestamp = uint64(begin);
    gen.end_timestamp   = uint64(end);
    generation_ids.push(id);
  }

  function addApprovers(AspectTestActor[] memory actors) internal {
    for (uint n = 0; n < actors.length; n++) {
      approvers.push(address(actors[n]));
      approvers_idx[address(actors[n])] = n + 1;
    }
  }

  function addRecord(
    mapping(bytes32 => shared.Record) storage map,
    address                            recipient,
    bytes32                            gen_id,
    bytes20                            details,
    bytes32                            content
  ) internal returns(bytes32) {
    shared.Record memory rec = shared.Record({
      recipient:  recipient,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    map[hash] = rec;
    generations[gen_id].records.push(hash);
    records_by_recipient[recipient].push(hash);
    return hash;
  }
}
