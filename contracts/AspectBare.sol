// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Aspect.sol";

using { shared.setBit } for bytes;

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
        delete records_by_recipient[pending_records[hash].recipient];
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

  function addPendingRecordBare(
    address            recipient,
    bytes32            gen_id,
    uint64             timestamp,
    bytes24            details,
    bytes32            content,
    address[] calldata apprs
  ) external {
    addRecordImpl(recipient, gen_id, timestamp, details, content, apprs);
  }

  function addApproversBare(address[] calldata accs, address[] calldata enable) external {
    for (uint n = 0; n < accs.length; n++) {
      approvers.push(accs[n]);
      approvers_idx[accs[n]] = n + 1;
      for (uint m = 0; m < enable.length; m++) {
        if (accs[n] == enable[m]) approvers_mask.setBit(n);
      }
    }
  }

  function setGenerationApproversBare(address[] calldata accs, bytes32 gen_id) external {
    shared.Generation storage gen = generations[gen_id];
    for (uint n = 0; n < accs.length; n++) {
      gen.approvers_mask.setBit(approvers_idx[accs[n]] - 1);
    }
  }

  function addRecordImpl(
    address            recipient,
    bytes32            gen_id,
    uint64             timestamp,
    bytes24            details,
    bytes32            content,
    address[] calldata apprs
  ) internal {
    shared.Record memory rec = shared.Record({
      recipient:  recipient,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  timestamp,
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    pending_records[hash] = rec;
    bytes storage bts = pending_records[hash].approvers;
    for (uint n = 0; n < apprs.length; n++) {
      for (uint m = 0; m < approvers.length; m++) {
        if (approvers[m] == apprs[n]) {
          bts.setBit(m);
          break;
        }
      }
    }
    generations[gen_id].records.push(hash);
    records_by_recipient[recipient].push(hash);
  }
}
