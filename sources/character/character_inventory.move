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

  // ╔════════════════ [ Constant ] ═════════════════════════════════════════ ]

  const EInvalidSlot: u64 = 101;

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct SlotKey has copy, drop, store {
    slot: String,
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Equip an item onto a character, users must select the character first.
  /// Only a purchasecap of the item can be equipped to avoid creating a protected policy.
  /// The purchasecap ensure the NFT stays in the kiosk and is not mutated or transfered
  /// To unselect a character, the user must unequip all items.
  public fun equip_item<T: key + store>(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    character_id: ID,
    slot: String,
    item: PurchaseCap<T>,
    version: &Version,
    ctx: &mut TxContext
  ) {
    version.assert_latest();
    verify_slot(slot);

    events::emit_item_equip_event(
      character_id,
      slot,
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
    slot: String,
    version: &Version,
    ctx: &mut TxContext
  ): PurchaseCap<T> {
    version.assert_latest();
    verify_slot(slot);

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
      slot,
      object::id(kiosk),
      cap.purchase_cap_item(),
    );

    cap
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun verify_slot(slot: String) {
    assert!(
      slot == b"hat".to_string() ||
      slot == b"amulet".to_string() ||
      slot == b"cloack".to_string() ||
      slot == b"left_ring".to_string() ||
      slot == b"right_ring".to_string() ||
      slot == b"belt".to_string() ||
      slot == b"boots".to_string() ||
      slot == b"pet".to_string() ||
      slot == b"weapon".to_string() ||
      slot == b"relic_1".to_string() ||
      slot == b"relic_2".to_string() ||
      slot == b"relic_3".to_string() ||
      slot == b"relic_4".to_string() ||
      slot == b"relic_5".to_string() ||
      slot == b"relic_6".to_string() ||
      slot == b"title".to_string(),
      EInvalidSlot
    );
  }
}