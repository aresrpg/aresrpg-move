module aresrpg::character_inventory {

  // This module manages the inventory of a character
  // It allows to equip and unequip items.

  use std::{
    string::String,
  };

  use sui::{
    kiosk::{PurchaseCap, Kiosk, KioskOwnerCap},
  };

  use aresrpg::{
    version::Version,
    extension,
    events
  };

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct SlotKey has copy, drop, store {
    slot: Slot,
  }

  public enum Slot has store, copy, drop {
    hat,
    amulet,
    cloack,
    left_ring,
    right_ring,
    belt,
    boots,
    pet,
    weapon,
    relic_1,
    relic_2,
    relic_3,
    relic_4,
    relic_5,
    relic_6,
    title,
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun slot_to_string(self: Slot): String {
      match (self) {
          Slot::hat => b"hat".to_string(),
          Slot::amulet => b"amulet".to_string(),
          Slot::cloack => b"cloack".to_string(),
          Slot::left_ring => b"left_ring".to_string(),
          Slot::right_ring => b"right_ring".to_string(),
          Slot::belt => b"belt".to_string(),
          Slot::boots => b"boots".to_string(),
          Slot::pet => b"pet".to_string(),
          Slot::weapon => b"weapon".to_string(),
          Slot::relic_1 => b"relic_1".to_string(),
          Slot::relic_2 => b"relic_2".to_string(),
          Slot::relic_3 => b"relic_3".to_string(),
          Slot::relic_4 => b"relic_4".to_string(),
          Slot::relic_5 => b"relic_5".to_string(),
          Slot::relic_6 => b"relic_6".to_string(),
          Slot::title => b"title".to_string(),
      }
  }

  /// Equip an item onto a character, users must select the character first.
  /// Only a purchasecap of the item can be equipped to avoid creating a protected policy.
  /// The purchasecap ensure the NFT stays in the kiosk and is not mutated or transfered
  /// To unselect a character, the user must unequip all items.
  public fun equip_item<T: key + store>(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    character_id: ID,
    slot: Slot,
    item: PurchaseCap<T>,
    version: &Version,
    ctx: &mut TxContext
  ) {
    version.assert_latest();

    events::emit_item_equip_event(
      character_id,
      slot.slot_to_string(),
      object::id(kiosk),
      item.purchase_cap_item(),
    );

    let character = extension::borrow_character_mut(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );
    let inventory = character.borrow_inventory_mut();

    inventory.add(SlotKey { slot }, item);
  }

  /// Unequip an item from a selected character (in extension)
  /// All items have to be unequipped before the character can be withdrawn
  public fun unequip_item<T: key + store>(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    character_id: ID,
    slot: Slot,
    version: &Version,
    ctx: &mut TxContext
  ): PurchaseCap<T> {
    version.assert_latest();

    let character = extension::borrow_character_mut(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );
    let inventory = character.borrow_inventory_mut();
    let cap = inventory.remove<SlotKey, PurchaseCap<T>>(SlotKey { slot });

    events::emit_item_unequip_event(
      character_id,
      slot.slot_to_string(),
      object::id(kiosk),
      cap.purchase_cap_item(),
    );

    cap
  }

}