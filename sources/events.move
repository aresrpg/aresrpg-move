module aresrpg::events;

use std::string::String;
use sui::event::emit;

// This module defines the events that are used in the AresRPG game.

// ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

public struct ItemEquipEvent has copy, drop {
  character_id: ID,
  slot: String,
  kiosk_id: ID,
  item_id: ID,
}

public struct ItemUnequipEvent has copy, drop {
  character_id: ID,
  slot: String,
  kiosk_id: ID,
  item_id: ID,
}

public struct ItemMintEvent has copy, drop {
  item_id: ID,
  kiosk_id: ID,
}

public struct ItemUpdateEvent has copy, drop {
  item_id: ID,
}

public struct ItemDestroyEvent has copy, drop {
  item_id: ID,
}

public struct AdminCapDeleteEvent has copy, drop {
  cap_id: ID,
}

public struct CharacterCreateEvent has copy, drop {
  character_id: ID,
  kiosk_id: ID,
}

public struct CharacterUpdateEvent has copy, drop {
  character_id: ID,
}

public struct CharacterDeleteEvent has copy, drop {
  character_id: ID,
}

public struct PetFeedEvent has copy, drop {
  pet_id: ID,
}

public struct SaleCreateEvent has copy, drop {
  sale_id: ID,
}

public struct SaleDeleteEvent has copy, drop {
  sale_id: ID,
}

public struct ItemMergeEvent has copy, drop {
  target_item_id: ID,
  kiosk_id: ID,
  item_id: ID,
  final_amount: u32,
}

public struct ItemSplitEvent has copy, drop {
  item_id: ID,
  kiosk_id: ID,
  new_item_id: ID,
  amount: u32,
}

// ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

public(package) fun emit_item_equip_event(
  character_id: ID,
  slot: String,
  kiosk_id: ID,
  item_id: ID,
) {
  emit(ItemEquipEvent {
    character_id,
    slot,
    kiosk_id,
    item_id,
  });
}

public(package) fun emit_item_unequip_event(
  character_id: ID,
  slot: String,
  kiosk_id: ID,
  item_id: ID,
) {
  emit(ItemUnequipEvent {
    character_id,
    slot,
    kiosk_id,
    item_id,
  });
}

public(package) fun emit_character_create_event(character_id: ID, kiosk_id: ID) {
  emit(CharacterCreateEvent {
    character_id,
    kiosk_id,
  });
}

public(package) fun emit_character_delete_event(character_id: ID) {
  emit(CharacterDeleteEvent {
    character_id,
  });
}

public(package) fun emit_pet_feed_event(pet_id: ID) {
  emit(PetFeedEvent {
    pet_id,
  });
}

public(package) fun emit_item_mint_event(item_id: ID, kiosk_id: ID) {
  emit(ItemMintEvent {
    item_id,
    kiosk_id,
  });
}

public(package) fun emit_item_destroy_event(item_id: ID) {
  emit(ItemDestroyEvent {
    item_id,
  });
}

public(package) fun emit_admin_cap_delete_event(cap_id: ID) {
  emit(AdminCapDeleteEvent {
    cap_id,
  });
}

public(package) fun emit_sale_create_event(sale_id: ID) {
  emit(SaleCreateEvent {
    sale_id,
  });
}

public(package) fun emit_sale_delete_event(sale_id: ID) {
  emit(SaleDeleteEvent {
    sale_id,
  });
}

public(package) fun emit_item_merge_event(
  target_item_id: ID,
  item_id: ID,
  final_amount: u32,
  kiosk_id: ID,
) {
  emit(ItemMergeEvent {
    target_item_id,
    item_id,
    final_amount,
    kiosk_id,
  });
}

public(package) fun emit_item_split_event(item_id: ID, kiosk_id: ID, new_item_id: ID, amount: u32) {
  emit(ItemSplitEvent {
    item_id,
    kiosk_id,
    new_item_id,
    amount,
  });
}

public(package) fun emit_item_update_event(item_id: ID) {
  emit(ItemUpdateEvent {
    item_id,
  });
}

public(package) fun emit_character_update_event(character_id: ID) {
  emit(CharacterUpdateEvent {
    character_id,
  });
}
