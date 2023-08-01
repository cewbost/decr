// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./actor.sol";
import "../../contracts/Aspect.sol";

using { setBit, getBit } for bytes;

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
      gen.end_timestamp   = uint64(end);
    }
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
    Record[] memory ret = new Record[](num);
    for (uint n = 0; n < num; n++) ret[n] = recs[n];
    return ret;
  }

  function setApprovers(AspectTestActor[] memory actors) internal {
    for (uint n = 0; n < actors.length; n++) {
      approvers.push(address(actors[n]));
      approvers_idx[address(actors[n])] = n + 1;
    }
  }

  function setApprovers(AspectTestActor[] memory actors, uint generation) internal {
    setApprovers(actors);
    for (uint n = 0; n < actors.length; n++) {
      generations[generation].approvers_mask.setBit(n);
    }
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
    address[] memory ret = new address[](count);
    for (uint n = 0; n < count; n++) ret[n] = res[n];
    return ret;
  }

  function getApprovers(uint generation) internal view returns(address[] memory) {
    uint              len   = approvers.length;
    Record    storage gen   = generations[generation];
    address[] memory  res   = new address[](len);
    uint              count = 0;
    for (uint n = 0; n < len; n++) if (gen.approvers_mask.getBit(n)) res[count++] = approvers[n];
    address[] memory ret = new address[](count);
    for (uint n = 0; n < count; n++) ret[n] = res[n];
    return ret;
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
  }

  function purgeApprovers() internal {
    uint len = approvers.length;
    approvers_mask = "";
    for (uint n = 0; n < len; n++) delete approvers_idx[approvers[n]];
    for (uint n = 0; n < len; n++) approvers.pop();
  }
}
