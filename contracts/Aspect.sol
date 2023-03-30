// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./Bitset.sol";

struct Record {
  address recipient;
  uint32  generation;
  uint64  timestamp;
  bytes20 details;
  bytes32 content;
  bytes   approvers;
}

contract Aspect is Owned {

  mapping(address => Record[]) records;
  address[]                    approvers;
  bytes                        approvers_mask;

  uint                         auto_cleaning_deadline = 1 << 63;
  uint                         first_pending_issue    = 0;
  uint                         last_pending_issue     = 0;

  mapping(uint => Record)      pending_records;
  mapping(address => uint[])   pending_records_index;

  function request(uint32 generation, bytes20 details, bytes32 content) external {
    uint[] storage issues = pending_records_index[msg.sender];
    uint slot = getIssueSlotForGeneration(issues, generation);
    uint issue = last_pending_issue;
    last_pending_issue++;
    pending_records[issue] = Record({
      recipient:  msg.sender,
      generation: generation,
      timestamp:  uint64(block.timestamp),
      details:    details,
      content:    content,
      approvers:  ""
    });
    issues[slot] = issue;
  }

  function grant(uint issue) external {}

  function reject(uint issue) external {}

  function grantApprover(address approver) external {}

  function revokeApprover(address approver) external {}

  function approve(uint issue) external {}

  function setAutoCleaningDeadline(uint deadline) external {
    auto_cleaning_deadline = deadline;
  }

  function getIssueSlotForGeneration(uint[] storage issues, uint32 generation) internal returns(uint) {
    uint slot;
    for (slot = 0; slot < issues.length; slot++) {
      uint issue = issues[slot];
      if (pending_records[issue].generation == generation) {
        delete pending_records[issue];
        return slot;
      }
    }
    issues.push();
    return slot;
  }
}
