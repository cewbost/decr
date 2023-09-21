// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Aspect.sol";

contract AspectBare is Aspect {

  constructor(string memory n) Aspect(n) {}

  function clearBare() external {
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
    for (uint n = len; n > 0; n--) {
      delete approvers_idx[approvers[n - 1]];
      approvers.pop();
    }
    approvers_mask = "";
  }

  function addGenerationBare(uint begin, uint end, bytes32 id) external {
    shared.Generation storage gen = generations[id];
    gen.begin_timestamp = uint64(begin);
    gen.end_timestamp   = uint64(end);
    generation_ids.push(id);
  }

  function addRecordBare(
    address recipient,
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external {
    shared.Record memory rec = shared.Record({
      recipient:  recipient,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    records[hash] = rec;
    generations[gen_id].records.push(hash);
    records_by_recipient[recipient].push(hash);
  }
}
