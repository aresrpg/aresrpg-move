module aresrpg::character_inventory {

  // This module manages the inventory of a character
  // It allows to equip and unequip items.

  use std::{
    string::{utf8, String},
  };

  use sui::{
    kiosk::{PurchaseCap, Kiosk, KioskOwnerCap},
  };

  use aresrpg::{
    version::Version,
    extension
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EInvalidSLot: u64 = 101;

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

    assert!(item_slot_valid(slot), EInvalidSLot);

    let character = extension::borrow_character_mut(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );
    let inventory = character.borrow_inventory_mut();

    inventory.add(slot, item);
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

    assert!(item_slot_valid(slot), EInvalidSLot);

    let character = extension::borrow_character_mut(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );
    let inventory = character.borrow_inventory_mut();

    inventory.remove(slot)
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun item_slot_valid(slot: String): bool {
    slot == utf8(b"hat") ||
    slot == utf8(b"amulet") ||
    slot == utf8(b"cloack") ||
    slot == utf8(b"left_ring") ||
    slot == utf8(b"right_ring") ||
    slot == utf8(b"belt") ||
    slot == utf8(b"boots") ||
    slot == utf8(b"pet") ||
    slot == utf8(b"weapon") ||
    slot == utf8(b"relic_1") ||
    slot == utf8(b"relic_2") ||
    slot == utf8(b"relic_3") ||
    slot == utf8(b"relic_4") ||
    slot == utf8(b"relic_5") ||
    slot == utf8(b"relic_6") ||
    slot == utf8(b"title")
  }

}