// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ClaimReceiver.sol";
import "./DecisionPolicy.sol";

contract DecrFacilitator {

  struct ActionSlot {
    uint               next;
    uint               prev;
    uint               signing_deadline;
    uint               claiming_start;
    uint               claiming_deadline;
    DecrClaimReceiver  receiver;
    DecrDecisionPolicy decision_policy;
    address            requester;
    uint128            action_id;
    uint128            issue_id;
    address[]          signatures;
  }

  ActionSlot[] private  actions;
  uint         private  unusedSlot;
  uint         private  linkedSlot;

  uint         constant deadline_max = 365 days;
  
  constructor() {
    unusedSlot = 0;
    linkedSlot = type(uint).max;
    actions.push().next = type(uint).max;
  }
  
  function initiate(
    address            requester,
    uint128            action_id,
    uint128            issue_id,
    uint               signing_time,
    uint               claiming_start,
    uint               claiming_time,
    DecrDecisionPolicy decision_policy
  ) external returns (uint) {
    require(
      claiming_start < claiming_time &&
      signing_time <= claiming_time &&
      claiming_time <= deadline_max
    );
    clean(5);
    uint slot = linkSlot();
    ActionSlot storage action = actions[slot];
    action.requester         = requester;                        
    action.action_id         = action_id;                        
    action.issue_id          = issue_id;                         
    action.signing_deadline  = block.timestamp + signing_time;
    action.claiming_start    = block.timestamp + claiming_start;
    action.claiming_deadline = block.timestamp + claiming_time;
    action.decision_policy   = decision_policy;                  
    action.receiver          = DecrClaimReceiver(msg.sender);
    action.signatures        = new address[](0);
    return slot;
  }
  
  function sign(address receiver, uint128 issue_id, uint slot) external {
    ActionSlot storage action = actions[slot];
    require(
      action.prev != type(uint).max &&
      block.timestamp <= action.signing_deadline &&
      address(action.receiver) == receiver &&
      action.issue_id == issue_id
    );
    clean(5);
    address[] storage signatures = action.signatures;
    for (uint i = 0; i < signatures.length; i++) {
      require(msg.sender != signatures[i]);
    }
    signatures.push() = msg.sender;
  }

  function claim(address receiver, uint128 issue_id, uint slot) external returns (bool) {
    ActionSlot storage action = actions[slot];
    require(
      action.prev != type(uint).max &&
      block.timestamp <= action.claiming_deadline &&
      address(action.receiver) == receiver &&
      action.issue_id == issue_id
    );
    clean(5);
    if (action.decision_policy.approveClaim(action.action_id, action.signatures)) {
      action.receiver.receiveClaim(action.requester, action.action_id, action.issue_id);
      unlinkSlot(slot);
      return true;
    } else {
      return false;
    }
  }
  
  function linkSlot() private returns (uint) {
    uint slot = unusedSlot;
    unusedSlot = actions[unusedSlot].next;
    if (unusedSlot == type(uint).max) {
      unusedSlot = actions.length;
      actions.push().next = type(uint).max;
    }
    ActionSlot storage action = actions[slot];
    if (linkedSlot == type(uint).max) {
      action.next = slot;
      action.prev = slot;
    } else {
      uint next = linkedSlot;
      uint prev = actions[next].prev;
      actions[next].prev = slot;
      actions[prev].next = slot;
      action.next = next;
      action.prev = prev;
    }
    linkedSlot = slot;
    return slot;
  }
  
  function unlinkSlot(uint slot) private {
    ActionSlot storage action = actions[slot];
    if (action.next == slot) {
      linkedSlot = type(uint).max;
    } else {
      uint next = action.next;
      uint prev = action.prev;
      actions[next].prev = prev;
      actions[prev].next = next;
      linkedSlot = next;
    }
    action.next = unusedSlot;
    action.prev = type(uint).max;
    unusedSlot = slot;
  }
  
  function clean(uint num) internal {
    if (linkedSlot == type(uint).max) return;
    for (uint n = 0; n < num; n++) {
      ActionSlot memory action = actions[linkedSlot];
      if (action.claiming_deadline < block.timestamp) {
        unlinkSlot(linkedSlot);
        if (linkedSlot == type(uint).max) return;
      } else {
        linkedSlot = action.next;
      }
    }
  }
}
