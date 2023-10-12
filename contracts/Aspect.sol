// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AspectImpl.sol";

using { getBit } for bytes;

contract Aspect is AspectImpl {

  constructor(bytes32 t, address owner) AspectImpl(t, owner) {}

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
    uint len = generation_ids.length;
    uint alen = approvers.length;
    GenerationResponse[] memory res = new GenerationResponse[](len);
    for (uint n = 0; n < len; n++) {
      bytes32 gen_id = generation_ids[n];
      Generation storage generation = generations[gen_id];
      address[] memory apps = new address[](alen);
      uint acount = 0;
      for (uint a = 0; a < alen; a++) {
        if (generation.approvers_mask.getBit(a)) apps[acount++] = approvers[a];
      }
      address[] memory napps = new address[](acount);
      for (uint a = 0; a < acount; a++) napps[a] = apps[a];
      res[n] = GenerationResponse({
        id:              gen_id,
        begin_timestamp: generation.begin_timestamp,
        end_timestamp:   generation.end_timestamp,
        approvers:       napps
      });
    }
    return res;
  }

  function getPendingRecordsByGeneration(
    bytes32 gen_id
  ) public view generationExists(gen_id) returns(RecordResponse[] memory) {
    return getRecs(generations[gen_id].records);
  }

  function getPendingRecordsByRecipient(
    address account
  ) public view returns(RecordResponse[] memory) {
    return getRecs(records_by_recipient[account]);
  }

  function getRecs(bytes32[] storage recs) internal view returns(RecordResponse[] memory) {
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

  modifier generationExists(bytes32 id) {
    require(generations[id].end_timestamp != 0, "generation does not exist");
    _;
  }
}
