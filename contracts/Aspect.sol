// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AspectState.sol";

function getBit(bytes memory bts, uint idx) pure returns(bool) {
  return bts.length > idx / 8? (bts[idx / 8] & toBit(idx % 8)) != 0 : false;
}

using { getBit } for bytes;

contract Aspect is AspectState {

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

  constructor(bytes32 t, address owner) AspectState(t, owner) {}

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
    insertGeneration_(id, begin, end, approvers_mask);
  }

  function amIOwner() external view returns(bool) {
    return authorized();
  }

  function getApprovers() external view returns(ApproverResponse[] memory) {
    uint num = approvers.length;
    ApproverResponse[] memory res = new ApproverResponse[](num);
    for (uint n = 0; n < num; n++) {
      address approver = approvers[n];
      res[n].approver  = approver;
      res[n].enabled   = approvers_mask.getBit(approvers_idx[approver] - 1);
    }
    return res;
  }

  function getGenerations() external view returns(GenerationResponse[] memory) {
    (bytes32[] memory ids, Generation[] memory gens) = getGenerations_();
    GenerationResponse[] memory res = new GenerationResponse[](gens.length);
    for (uint n = 0; n < gens.length; n++) {
      res[n] = GenerationResponse({
        id:              ids[n],
        begin_timestamp: gens[n].begin_timestamp,
        end_timestamp:   gens[n].end_timestamp,
        approvers:       maskToApproverList(gens[n].approvers_mask)
      });
    }
    return res;
  }

  function getPendingRecordsByGeneration(
    bytes32 gen_id
  ) external view returns(RecordResponse[] memory) {
    return getPendingRecords(getGeneration_(gen_id).records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) external view returns(RecordResponse[] memory) {
    return getPendingRecords(records_by_recipient[account]);
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
      res[n].approvers = maskToApproverList(recs[n].approvers);
    }
    return res;
  }

  function maskToApproverList(bytes memory mask) internal view returns(address[] memory) {
    uint alen = approvers.length;
    address[] memory apps = new address[](alen);
    uint acount = 0;
    for (uint a = 0; a < alen; a++) {
      if (mask.getBit(a)) apps[acount++] = approvers[a];
    }
    address[] memory res = new address[](acount);
    for (uint a = 0; a < acount; a++) res[a] = apps[a];
    return res;
  }
}
