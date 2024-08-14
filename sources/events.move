module aresrpg::events {

  // This module defines the events that are used in the AresRPG game.

  use std::string::String;

  use sui::{
    event::emit
  };

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

  public struct ItemWithdrawEvent has copy, drop {
    item_id: ID,
    kiosk_id: ID,
  }

  public struct ItemDestroyEvent has copy, drop {
    item_id: ID,
  }

  public struct CharacterCreateEvent has copy, drop {
    character_id: ID,
    kiosk_id: ID
  }

  public struct CharacterSelectEvent has copy, drop {
    character_id: ID,
  }

  public struct CharacterUnselectEvent has copy, drop {
    character_id: ID,
    kiosk_id: ID
  }

  public struct CharacterDeleteEvent has copy, drop {
    character_id: ID
  }

  public struct PetFeedEvent has copy, drop {
    pet_id: ID
  }

  public struct AresRpgExtensionInstallEvent has copy, drop {
    kiosk_id: ID
  }

  public struct RecipeCreateEvent has copy, drop {
    recipe_id: ID
  }

  public struct RecipeDeleteEvent has copy, drop {
    recipe_id: ID
  }

  public struct ItemMergeEvent has copy, drop {
    target_item_id: ID,
    target_kiosk_id: ID,
    item_id: ID,
    final_amount: u32,
    kiosk_id: ID,
  }

  public struct ItemSplitEvent has copy, drop {
    item_id: ID,
    kiosk_id: ID,
    new_item_id: ID,
    amount: u32,
  }

  public struct FinishedCraftEvent has copy, drop {
    id: ID,
    recipe_id: ID,
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun emit_item_equip_event(
    character_id: ID,
    slot: String,
    kiosk_id: ID,
    item_id: ID
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
    item_id: ID
  ) {
    emit(ItemUnequipEvent {
      character_id,
      slot,
      kiosk_id,
      item_id,
    });
  }

  public(package) fun emit_character_create_event(
    character_id: ID,
    kiosk_id: ID
  ) {
    emit(CharacterCreateEvent {
      character_id,
      kiosk_id,
    });
  }

  public(package) fun emit_character_select_event(
    character_id: ID,
  ) {
    emit(CharacterSelectEvent {
      character_id,
    });
  }

  public(package) fun emit_character_unselect_event(
    character_id: ID,
    kiosk_id: ID
  ) {
    emit(CharacterUnselectEvent {
      character_id,
      kiosk_id
    });
  }

  public(package) fun emit_character_delete_event(
    character_id: ID
  ) {
    emit(CharacterDeleteEvent {
      character_id
    });
  }

  public(package) fun emit_pet_feed_event(
    pet_id: ID
  ) {
    emit(PetFeedEvent {
      pet_id
    });
  }

  public(package) fun emit_item_mint_event(
    item_id: ID,
    kiosk_id: ID
  ) {
    emit(ItemMintEvent {
      item_id,
      kiosk_id
    });
  }

  public(package) fun emit_item_withdraw_event(
    item_id: ID,
    kiosk_id: ID
  ) {
    emit(ItemWithdrawEvent {
      item_id,
      kiosk_id
    });
  }

  public(package) fun emit_item_destroy_event(
    item_id: ID,
  ) {
    emit(ItemDestroyEvent {
      item_id,
    });
  }

  public(package) fun emit_extension_install_event(
    kiosk_id: ID
  ) {
    emit(AresRpgExtensionInstallEvent {
      kiosk_id
    });
  }

  public(package) fun emit_recipe_create_event(
    recipe_id: ID
  ) {
    emit(RecipeCreateEvent {
      recipe_id
    });
  }

  public(package) fun emit_recipe_delete_event(
    recipe_id: ID
  ) {
    emit(RecipeDeleteEvent {
      recipe_id
    });
  }

  public(package) fun emit_item_merge_event(
    target_item_id: ID,
    target_kiosk_id: ID,
    item_id: ID,
    final_amount: u32,
    kiosk_id: ID
  ) {
    emit(ItemMergeEvent {
      target_item_id,
      target_kiosk_id,
      item_id,
      final_amount,
      kiosk_id
    });
  }

  public(package) fun emit_item_split_event(
    item_id: ID,
    kiosk_id: ID,
    new_item_id: ID,
    amount: u32,
  ) {
    emit(ItemSplitEvent {
      item_id,
      kiosk_id,
      new_item_id,
      amount
    });
  }

  public(package) fun emit_finished_craft_event(
    id: ID,
    recipe_id: ID
  ) {
    emit(FinishedCraftEvent {
      id,
      recipe_id
    });
  }
}