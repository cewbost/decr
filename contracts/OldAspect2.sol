// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./Bitset.sol";

struct OldRecord {
  address recipient;
  uint32  generation;
  uint64  timestamp;
  bytes20 details;
  bytes32 content;
  bytes   approvers;
}

contract OldAspect2 is Owned {

  mapping(address => OldRecord[])                records;

  address[]                                   approvers;
  bytes                                       approvers_mask;

  uint                                        auto_cleaning_deadline = 1 << 63;
  uint                                        first_pending_issue    = 1;
  uint                                        last_pending_issue     = 1;
  mapping(uint => OldRecord)                     pending_records;
  mapping(address => mapping(uint32 => uint)) pending_records_index;

  function generations(address recipient) public view returns(uint32[] memory) {
    OldRecord[] storage recs = records[recipient];
    uint32[] memory  gens = new uint32[](recs.length);
    for (uint idx = 0; idx < gens.length; idx++) gens[idx] = recs[idx].generation;
    return gens;
  }

  function getRecord(
    address recipient,
    uint32  generation
  ) public view returns(uint64, bytes20, bytes32) {
    OldRecord[] storage recs = records[recipient];
    uint idx;
    for (idx = 0; idx < recs.length; idx++) {
      if (recs[idx].generation == generation) {
        if (idx == 0) break;
        else idx--;
      }
    }
    OldRecord storage rec = recs[idx];
    return (rec.timestamp, rec.details, rec.content);
  }

  function request(uint32 generation, bytes20 details, bytes32 content) external {
    uint issue = pending_records_index[msg.sender][generation];
    if (issue == 0) {
      (uint64 timestamp,,) = getRecord(msg.sender, generation);
      require(timestamp == 0);
    } else {
      delete pending_records[issue];
    }
    issue = last_pending_issue;
    last_pending_issue++;
    pending_records[issue] = OldRecord({
      recipient:  msg.sender,
      generation: generation,
      timestamp:  uint64(block.timestamp + auto_cleaning_deadline),
      details:    details,
      content:    content,
      approvers:  ""
    });
    pending_records_index[msg.sender][generation] = issue;
  }

  function grant(
    address recipient,
    uint32 generation
  ) external onlyOwner validIssue(recipient, generation) {
    uint issue = pending_records_index[recipient][generation];
    OldRecord storage rec = pending_records[issue];
    rec.timestamp = uint64(block.timestamp);
    records[rec.recipient].push(rec);
    removePendingRecord(issue);
    clean();
  }

  function reject(
    address recipient,
    uint32 generation
  ) external onlyOwner validIssue(recipient, generation) {
    removePendingRecord(pending_records_index[recipient][generation]);
    clean();
  }

  function grantApprover(address approver) external onlyOwner {}

  function revokeApprover(address approver) external onlyOwner {}

  function approve(
    address recipient,
    uint32 generation
  ) external validIssue(recipient, generation) {}

  function setAutoCleaningDeadline(uint deadline) external onlyOwner {
    auto_cleaning_deadline = deadline;
  }

  function clean() internal {
    uint issue = first_pending_issue;
    for (; issue < last_pending_issue; first_pending_issue++) {
      removePendingRecord(issue);
    }
    first_pending_issue = issue;
  }

  function removePendingRecord(uint issue) internal {
    OldRecord storage rec = pending_records[issue];
    delete pending_records_index[rec.recipient][rec.generation];
    delete pending_records[issue];
  }

  modifier validIssue(address recipient, uint32 generation) {
    uint64 timestamp = pending_records[pending_records_index[recipient][generation]].timestamp;
    require(timestamp > 0 && timestamp < block.timestamp);
    _;
  }
}
