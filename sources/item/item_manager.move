module aresrpg::item_manager {

  // This module is responsible for managing items (minting, transfering, etc.)

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::TransferPolicy,
    kiosk_extension,
  };

  use std::string::{String};

  use aresrpg::{
    item::{Self as a_item, Item, ItemCategory},
    admin::AdminCap,
    version::Version,
    extension::{
      AresRPG,
      place_item_in_extension,
      take_item_from_extension,
    },
    promise::{await, Promise},
    protected_policy::AresRPG_TransferPolicy,
    events,
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EExtensionNotInstalled: u64 = 101;

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Allows a kiosk owner to withdraw items from the extention to their kiosk.
  /// This can be used when the player win items after a fight
  public fun withdraw(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &TransferPolicy<Item>,
    item_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let item = take_item_from_extension(
      kiosk,
      kiosk_cap,
      item_id,
      ctx
    );

    events::emit_item_withdraw_event(
      object::id(&item),
      object::id(kiosk)
    );

    kiosk.lock(kiosk_cap, policy, item);
  }

  public fun destroy_item(
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
      ctx
    );

    item.destroy();
  }

  public fun split_item(
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

  public fun merge_items_single_kiosk(
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
      ctx
    );

    let kiosk_id = object::id(kiosk);
    let target_item = kiosk.borrow_mut<Item>(kiosk_cap, target_item_id);

    events::emit_item_merge_event(
      target_item_id,
      kiosk_id,
      item_id,
      item.amount() + target_item.amount(),
      kiosk_id
    );

    target_item.merge(item);
  }

  public fun merge_items_different_kiosk(
    target_kiosk: &mut Kiosk,
    target_kiosk_cap: &KioskOwnerCap,
    target_item_id: ID,
    item_kiosk: &mut Kiosk,
    item_kiosk_cap: &KioskOwnerCap,
    item_id: ID,
    protected_policy: &AresRPG_TransferPolicy<Item>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let item = protected_policy.extract_from_kiosk(
      item_kiosk,
      item_kiosk_cap,
      item_id,
      ctx
    );
    let target_kiosk_id = object::id(target_kiosk);
    let target_item = target_kiosk.borrow_mut<Item>(target_kiosk_cap, target_item_id);

    events::emit_item_merge_event(
      target_item_id,
      target_kiosk_id,
      item_id,
      item.amount() + target_item.amount(),
      object::id(item_kiosk)
    );

    target_item.merge(item);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to mint an item
  /// This is used to create items that players win during the gameplay
  /// The function return a promise to make sure the item is locked in the extension
  /// But before it can be augmented with stats and other properties
  public fun admin_mint(
    admin: &AdminCap,
    name: String,
    item_category: ItemCategory,
    item_set: String,
    item_type: String,
    level: u8,
    amount: u32,
    stackable: bool,
    ctx: &mut TxContext
  ): (Item, Promise<ID>) {
    admin.verify(ctx);

    let item = a_item::new(
      name,
      item_category,
      item_set,
      item_type,
      level,
      amount,
      stackable,
      ctx
    );

    let item_id = object::id(&item);

    (item, await(item_id))
  }

  public fun admin_lock_newly_minted(
    admin: &AdminCap,
    kiosk: &mut Kiosk,
    item: Item,
    promise: Promise<ID>,
    ctx: &mut TxContext
  ) {
    admin.verify(ctx);
    assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

    promise.resolve(object::id(&item));

    events::emit_item_mint_event(
      object::id(&item),
      object::id(kiosk)
    );

    place_item_in_extension(kiosk, item, ctx);
  }
}