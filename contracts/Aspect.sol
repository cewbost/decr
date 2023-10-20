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

  function getApprovers() public view returns(ApproverResponse[] memory) {
    uint num = approvers.length;
    ApproverResponse[] memory res = new ApproverResponse[](num);
    for (uint n = 0; n < num; n++) {
      address approver = approvers[n];
      res[n].approver  = approver;
      res[n].enabled   = approvers_mask.getBit(approvers_idx[approver] - 1);
    }
    return res;
  }

  function getGenerations() public view returns(GenerationResponse[] memory) {
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
  ) public view returns(RecordResponse[] memory) {
    return getRecs(getGeneration_(gen_id).records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) public view returns(RecordResponse[] memory) {
    return getRecs(records_by_recipient[account]);
  }

  function getRecs(bytes32[] memory recs) internal view returns(RecordResponse[] memory) {
    uint len           = recs.length;
    uint approvers_len = approvers.length;
    uint num_recs      = 0;
    RecordResponse[] memory res              = new RecordResponse[](len);
    address[]        memory approvers_buffer = new address[](approvers_len);
    for (uint n = 0; n < len; n++) {
      bytes32               hash = recs[n];
      Record storage rec  = pending_records[hash];
      if (rec.timestamp != 0) {
        res[num_recs].hash       = hash;
        res[num_recs].recipient  = rec.recipient;
        res[num_recs].generation = rec.generation;
        res[num_recs].timestamp  = rec.timestamp;
        res[num_recs].details    = rec.details;
        res[num_recs].content    = rec.content;
        uint num_approvers = 0;
        for (uint m = 0; m < approvers_len; m++) {
          if (getBit(rec.approvers, m)) {
            approvers_buffer[num_approvers++] = approvers[m];
          }
        }
        res[num_recs].approvers = truncate(approvers_buffer, num_approvers);
        num_recs++;
      }
    }
    return truncate(res, num_recs);
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

  function truncate(address[] memory arr, uint elems) internal pure returns(address[] memory) {
    address[] memory res = new address[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }

  function truncate(
    RecordResponse[] memory arr,
    uint elems
  ) internal pure returns(RecordResponse[] memory) {
    RecordResponse[] memory res = new RecordResponse[](elems);
    for (uint n = 0; n < elems; n++) res[n] = arr[n];
    return res;
  }
}
