// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AspectModel.sol";

contract Aspect is AspectModel {

  struct RecordResponse {
    bytes32   hash;
    address   recipient;
    bytes32   generation;
    uint64    timestamp;
    bytes24   details;
    bytes32   content;
    address[] approvers;
  }

  struct GenerationResponse {
    bytes32   id;
    uint64    begin_timestamp;
    uint64    end_timestamp;
    address[] approvers;
  }

  struct ApproverResponse {
    address approver;
    bool    enabled;
  }

  constructor(bytes32 t, address owner) AspectModel(t, owner) {}

  function changeOwnership(address new_owner) external onlyOwner {
    setOwner(new_owner);
  }

  function newGeneration(
    bytes32 id,
    uint64  begin,
    uint64  end
  ) external onlyOwner uniqueGeneration(id) {
    require(id != "",    "generation ID must be provided");
    require(begin < end, "ending must be before beginning");
    insertGeneration_(id, begin, end, getApproversMask_());
  }

  function request(
    bytes32 gen_id,
    bytes24 details,
    bytes32 content
  ) external activeGeneration(gen_id) {
    Record memory rec = Record({
      recipient:  msg.sender,
      generation: gen_id,
      details:    details,
      content:    content,
      timestamp:  uint64(block.timestamp),
      approvers:  ""
    });
    require(isNewRecord_(rec), "already exists");
    insertPendingRecord_(rec);
  }

  function grant(bytes32 hash) external onlyOwner pendingRecord(hash) {
    grant_(hash);
  }

  function approve(bytes32 hash) external pendingRecord(hash) {
    approve_(hash);
  }

  function clearGeneration(bytes32 gen) external onlyOwner {
    clearGeneration_(gen);
  }

  function enableApprover(address approver) external onlyOwner {
    setApproverState_(approver, true);
  }

  function enableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external onlyOwner {
    setGenerationApproverState_(approver, gen_id, true);
  }

  function disableApprover(address approver) external onlyOwner {
    setApproverState_(approver, false);
  }

  function disableApproverForGeneration(
    address approver,
    bytes32 gen_id
  ) external onlyOwner {
    setGenerationApproverState_(approver, gen_id, false);
  }

  function amIOwner() external view returns(bool) {
    return authorized();
  }

  function getApprovers() external view returns(ApproverResponse[] memory) {
    address[] memory apprs = getApprovers_();
    address[] memory enabled = getApprovers_(getApproversMask_());
    ApproverResponse[] memory res = new ApproverResponse[](apprs.length);
    for (uint n = 0; n < apprs.length; n++) res[n].approver = apprs[n];
    uint stepper = 0;
    for (uint n = 0; n < enabled.length; n++) {
      while (apprs[stepper] != enabled[n]) stepper++;
      res[stepper].enabled = true;
    }
    return res;
  }

  function getGeneration(bytes32 id) external view returns(GenerationResponse memory) {
    Generation memory gen = getGeneration_(id);
    GenerationResponse memory res = GenerationResponse({
      id:              id,
      begin_timestamp: gen.begin_timestamp,
      end_timestamp:   gen.end_timestamp,
      approvers:       getApprovers_(gen.approvers_mask)
    });
    return res;
  }

  function getPendingRecordsByGeneration(
    bytes32 gen_id
  ) external view returns(RecordResponse[] memory) {
    return getPendingRecords(getGeneration_(gen_id).records);
  }

  function getPendingRecordsByRecipient(
    address recipient
  ) external view returns(RecordResponse[] memory) {
    return getPendingRecords(getRecipientRecordIds_(recipient));
  }

  function getPendingRecords(bytes32[] memory ids) internal view returns(RecordResponse[] memory) {
    ids = filterRecordIdsPending_(ids);
    Record[] memory recs = getPendingRecords_(ids);
    RecordResponse[] memory res = new RecordResponse[](recs.length);
    for (uint n = 0; n < recs.length; n++) {
      res[n].hash = ids[n];
      res[n].recipient = recs[n].recipient;
      res[n].generation = recs[n].generation;
      res[n].timestamp = recs[n].timestamp;
      res[n].details = recs[n].details;
      res[n].content = recs[n].content;
      res[n].approvers = getApprovers_(recs[n].approvers);
    }
    return res;
  }
}
