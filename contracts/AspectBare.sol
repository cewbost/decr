// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Aspect.sol";

function setBit(bytes memory bts, uint idx) pure {
  uint   byte_idx = idx / 8;
  assert(byte_idx < bts.length);
  bts[byte_idx] = bts[byte_idx] | toBit(idx % 8);
}

using { setBit } for bytes;

contract AspectBare is Aspect {

  constructor(bytes32 n, address owner) Aspect(n, owner) {}

  function insertGeneration(
    bytes32 id,
    uint64 begin,
    uint64 end,
    address[] calldata apprs
  ) external {
    insertGeneration_(id, begin, end, approverListToMask(apprs));
  }

  function insertPendingRecord(
    address            recipient,
    bytes32            gen_id,
    uint64             timestamp,
    bytes24            details,
    bytes32            content,
    address[] calldata apprs
  ) external {
    Record memory rec = Record({
      recipient:  recipient,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  timestamp,
      approvers:  approverListToMask(apprs)
    });
    bytes32 hash = hashRecord(rec);
    insertPendingRecord_(hash, rec);
  }

  function setApprovers(address[] calldata accs, address[] calldata enable) external {
    for (uint n = 0; n < accs.length; n++) getsertApprover_(accs[n]);
    for (uint n = 0; n < enable.length; n++) setApproverState_(enable[n], true);
  }

  function approverListToMask(address[] memory list) internal view returns(bytes memory) {
    address[] memory apprs = getApprovers_();
    bytes memory res = new bytes((apprs.length + 7) / 8);
    for (uint n = 0; n < list.length; n++) {
      for (uint m = 0; m < apprs.length; m++) {
        if (list[n] == apprs[m]) {
          res.setBit(m);
          break;
        }
      }
    }
    return res;
  }

  modifier assertOnlyOwner() override {_;}
}
