// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {ActionReceived, DecrActionReceiver} from "./ActionReceiver.sol";
import {DecrDecisionPolicy} from "./DecisionPolicy.sol";

contract DecrFacilitator {

  struct Action {
    DecrActionReceiver receiver;
    DecrDecisionPolicy decision_policy;
    address            requester;
    bytes16            action_id;
    bytes16            issue_id;
  }
  
  struct ActionSlot {
    uint      signing_deadline;
    uint      claiming_start;
    uint      claiming_deadline;
    uint      next;
    uint      prev;
    Action    action;
    address[] signatures;
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
    ActionReceived calldata action,
    uint                    signing_time,   
    uint                    claiming_start, 
    uint                    claiming_time   
  ) external returns (address, bytes16, uint) {
    require(
      claiming_start < claiming_time &&
      signing_time <= claiming_time &&
      claiming_time <= deadline_max
    );
    clean(5);
    uint slot = linkSlot();
    ActionSlot storage action_slot = actions[slot];
    action_slot.signing_deadline = block.timestamp + signing_time;
    action_slot.claiming_start = block.timestamp + claiming_start;
    action_slot.claiming_deadline = block.timestamp + claiming_time;
    action_slot.action = Action({
      receiver:        DecrActionReceiver(msg.sender),
      decision_policy: action.decision_policy,
      requester:       action.requester,
      action_id:       action.action_id,
      issue_id:        action.issue_id
    });
    return (msg.sender, action.issue_id, slot);
  }
  
  function sign(address receiver, bytes16 issue_id, uint slot) external {
    ActionSlot storage action_slot = actions[slot];
    require(
      action_slot.prev != type(uint).max &&
      block.timestamp <= action_slot.signing_deadline &&
      address(action_slot.action.receiver) == receiver &&
      action_slot.action.issue_id == issue_id
    );
    clean(5);
    address[] storage signatures = action_slot.signatures;
    for (uint i = 0; i < signatures.length; i++) {
      require(msg.sender != signatures[i]);
    }
    signatures.push() = msg.sender;
  }
  
  function claim(address receiver, bytes16 issue_id, uint slot) external returns (bool) {
    ActionSlot storage action_slot = actions[slot];
    require(
      action_slot.prev != type(uint).max &&
      block.timestamp <= action_slot.claiming_deadline &&
      address(action_slot.action.receiver) == receiver &&
      action_slot.action.issue_id == issue_id
    );
    clean(5);
    Action storage action = action_slot.action;
    if (action.decision_policy.approveAction(action.action_id, action_slot.signatures)) {
      action.receiver.takeAction(ActionReceived({
        decision_policy: action.decision_policy,
        requester:       action.requester,
        action_id:       action.action_id,
        issue_id:        action.issue_id
      }));
      unlinkSlot(slot);
      return true;
    } else {
      return false;
    }
  }
  
  function linkSlot() internal returns (uint) {
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
  
  function unlinkSlot(uint slot) internal {
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
