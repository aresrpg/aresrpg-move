module aresrpg::item_api;

use aresrpg::{
  auth::AuthKey,
  character::Character,
  events,
  item::{Self, Item},
  item_damages::{ItemDamages, augment_with_damages},
  item_stats::{ItemStatistics, augment_with_stats},
  protected_policy::AresRPG_TransferPolicy,
  version::Version
};
use std::string::String;
use sui::{
  kiosk::{Kiosk, KioskOwnerCap},
  random::{Random, new_generator},
  transfer_policy::TransferPolicy
};

// ╔════════════════ [ Constant ] ═══════════════════════════════ ]

const EInvalidLastAmount: u64 = 101;

// ╔════════════════ [ Protected ] ═══════════════════════════════ ]

public fun new(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  policy: &TransferPolicy<Item>,
  name: String,
  item_category: String,
  item_set: String,
  item_type: String,
  level: u8,
  amount: u32,
  stackable: bool,
  stats: Option<ItemStatistics>,
  damages: vector<ItemDamages>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let mut minted_item = item::new(
    name,
    item_category,
    item_set,
    item_type,
    level,
    amount,
    stackable,
    ctx,
  );

  let item_id = object::id(&minted_item);

  if (stats.is_some()) {
    augment_with_stats(&mut minted_item, stats.destroy_some());
  };

  if (!damages.is_empty()) {
    augment_with_damages(&mut minted_item, damages);
  };

  kiosk.lock(kiosk_cap, policy, minted_item);

  events::emit_item_mint_event(
    item_id,
    object::id(kiosk),
  );
}

/// This function allows updating the amount of an item to avoid minting a new one.
public fun set_amount(
  _auth: &AuthKey,
  item: &mut Item,
  last_amount: u32,
  amount: u32,
  version: &Version,
) {
  version.assert_latest();

  assert!(last_amount == item.amount(), EInvalidLastAmount);

  item.set_amount(amount);
  events::emit_item_update_event(object::id(item));
}

public fun destroy(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  protected_policy: &AresRPG_TransferPolicy<Item>,
  item_id: ID,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let item = protected_policy.extract_from_kiosk(
    kiosk,
    kiosk_cap,
    item_id,
    ctx,
  );

  item.destroy();
}

public fun merge(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  target_item_id: ID,
  item_id: ID,
  protected_policy: &AresRPG_TransferPolicy<Item>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let item = protected_policy.extract_from_kiosk(
    kiosk,
    kiosk_cap,
    item_id,
    ctx,
  );

  let kiosk_id = object::id(kiosk);
  let target_item = kiosk.borrow_mut<Item>(kiosk_cap, target_item_id);

  events::emit_item_merge_event(
    target_item_id,
    item_id,
    item.amount() + target_item.amount(),
    kiosk_id,
  );

  target_item.merge(item);
}

/// Add experience to a character by consuming an item.
entry fun use_item_add_xp(
  _auth: &AuthKey,
  item_id: ID,
  character_id: ID,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  protected_policy: &AresRPG_TransferPolicy<Item>,
  random: &Random,
  min_xp: u32,
  max_xp: u32,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let item = protected_policy.extract_from_kiosk(
    kiosk,
    kiosk_cap,
    item_id,
    ctx,
  );

  let mut amount = item.amount();

  let character = kiosk.borrow_mut<Character>(kiosk_cap, character_id);
  let mut generator = new_generator(random, ctx);

  loop {
    if (amount == 0) {
      break
    };
    character.add_experience(generator.generate_u32_in_range(min_xp, max_xp));
    amount = amount - 1;
  };

  item.destroy();
}

// ╔════════════════ [ Public ] ════════════════════════════════════════════════ ]

public fun split(
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  policy: &TransferPolicy<Item>,
  item_id: ID,
  amount: u32,
  version: &Version,
  ctx: &mut TxContext,
): ID {
  version.assert_latest();

  let item = kiosk.borrow_mut<Item>(kiosk_cap, item_id);
  let new_item = item.split(amount, ctx);
  let new_item_id = object::id(&new_item);

  events::emit_item_split_event(
    item_id,
    object::id(kiosk),
    new_item_id,
    amount,
  );

  kiosk.lock(kiosk_cap, policy, new_item);

  new_item_id
}
