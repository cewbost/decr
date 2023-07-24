// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/Aspect.sol";
import "./actor.sol";

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

  function purgePendingRecords() internal {
    uint gens = generations.length;
    for (uint g = 0; g < gens; g++) {
      bytes32[] storage hashes = generations[g].pending_records;
      uint recs = hashes.length;
      for (uint n = 0; n < recs; n++) {
        bytes32 hash = hashes[n];
        delete pending_records_by_recipient[pending_records[hash].recipient];
        delete pending_records[hash];
      }
      delete generations[g].pending_records;
    }
  }

  function purgeGenerations() internal {
    while (generations.length > 0) generations.pop();
  }
}
