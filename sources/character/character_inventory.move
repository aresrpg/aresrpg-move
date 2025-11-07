module aresrpg::character_inventory;

use aresrpg::{
  auth::AuthKey,
  character::Character,
  events,
  protected_policy::{AresRPG_TransferPolicy, extract_from_kiosk},
  version::Version
};
use std::string::String;
use sui::{kiosk::{Kiosk, KioskOwnerCap}, transfer::Receiving, transfer_policy::TransferPolicy};

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

const EInvalidSlot: u64 = 101;
const EInvalidItem: u64 = 102;

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

public fun equip_item<T: key + store>(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  character: &mut Character,
  slot: String,
  item_id: ID,
  protected_policy: &AresRPG_TransferPolicy<T>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();
  verify_slot(slot);

  let item = protected_policy.extract_from_kiosk(
    kiosk,
    kiosk_cap,
    item_id,
    ctx,
  );

  events::emit_item_equip_event(
    object::id(character),
    slot,
    object::id(kiosk),
    object::id(&item),
  );

  let inventory = character.borrow_inventory_mut();

  inventory.insert(slot, item_id);
  transfer::public_transfer(item, character.id().to_address());
}

// ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

public fun unequip_item<T: key + store>(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  character: &mut Character,
  removed_item: Receiving<T>,
  slot: String,
  version: &Version,
  policy: &TransferPolicy<T>,
) {
  version.assert_latest();
  verify_slot(slot);

  let inventory = character.borrow_inventory_mut();
  let (_, item_id) = inventory.remove<String, ID>(&slot);

  let item = transfer::public_receive(character.uid_mut(), removed_item);

  assert!(item_id == object::id(&item), EInvalidItem);

  events::emit_item_unequip_event(
    object::id(character),
    slot,
    object::id(kiosk),
    object::id(&item),
  );

  kiosk.lock(kiosk_cap, policy, item)
}

// ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

fun verify_slot(slot: String) {
  assert!(
    slot == b"hat".to_string() ||
      slot == b"amulet".to_string() ||
      slot == b"cloak".to_string() ||
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
    EInvalidSlot,
  );
}
