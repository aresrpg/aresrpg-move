module aresrpg::character_inventory {

  // This module manages the inventory of a character
  // It allows to equip and unequip items.

  use std::string::String;

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
      slot.to_string(),
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
      slot,
      object::id(kiosk),
      cap.purchase_cap_item(),
    );

    cap
  }

}