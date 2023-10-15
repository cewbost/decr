// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Aspect.sol";

using { setBitStorage } for bytes;

contract AspectBare is Aspect {

  constructor(bytes32 n, address owner) Aspect(n, owner) {}

  function insertGeneration(bytes32 id, uint64 begin, uint64 end) external {
    insertGeneration_(id, begin, end, "");
  }

  function insertPendingRecord(
    address            recipient,
    bytes32            gen_id,
    uint64             timestamp,
    bytes24            details,
    bytes32            content,
    address[] calldata apprs
  ) external {
    addRecordImpl(recipient, gen_id, timestamp, details, content, apprs);
  }

  function setApprovers(address[] calldata accs, address[] calldata enable) external {
    for (uint n = 0; n < accs.length; n++) {
      approvers.push(accs[n]);
      approvers_idx[accs[n]] = n + 1;
      for (uint m = 0; m < enable.length; m++) {
        if (accs[n] == enable[m]) approvers_mask.setBitStorage(n);
      }
    }
  }

  function setGenerationApprovers(address[] calldata accs, bytes32 gen_id) external {
    Generation storage gen = generations[gen_id];
    for (uint n = 0; n < accs.length; n++) {
      gen.approvers_mask.setBitStorage(approvers_idx[accs[n]] - 1);
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
    Record memory rec = Record({
      recipient:  recipient,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  timestamp,
      approvers:  ""
    });
    bytes32 hash = hashRecord(rec);
    record_hashes[hash] = true;
    pending_records[hash] = rec;
    bytes storage bts = pending_records[hash].approvers;
    for (uint n = 0; n < apprs.length; n++) {
      for (uint m = 0; m < approvers.length; m++) {
        if (approvers[m] == apprs[n]) {
          bts.setBitStorage(m);
          break;
        }
      }
    }
    generations[gen_id].records.push(hash);
    records_by_recipient[recipient].push(hash);
  }

  modifier assertOnlyOwner() override {_;}
}
