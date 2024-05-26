module aresrpg::item_manager {

  // This module is responsible for managing items (minting, transfering, etc.)

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::TransferPolicy,
    kiosk_extension,
    event::emit
  };

  use std::string::{String};

  use aresrpg::{
    item::{Self as a_item, Item},
    admin::AdminCap,
    version::Version,
    extension::{
      AresRPG,
      place_item_in_extension,
      take_item_from_extension,
    },
    promise::{await, Promise},
    protected_policy::AresRPG_TransferPolicy,
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EExtensionNotInstalled: u64 = 101;

  // ╔════════════════ [ Events ] ════════════════════════════════════════════ ]

  public struct ItemMintEvent has copy, drop {
    item_id: ID,
    kiosk_id: ID,
  }

  public struct ItemWithdrawEvent has copy, drop {
    kiosk_id: ID,
    item_id: ID,
  }

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

    emit(ItemWithdrawEvent {
      kiosk_id: object::id(kiosk),
      item_id: object::id(&item)
    });

    kiosk.lock(kiosk_cap, policy, item);
  }

  public fun split_item(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &TransferPolicy<Item>,
    item_id: ID,
    amount: u32,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let item = kiosk.borrow_mut<Item>(kiosk_cap, item_id);
    let new_item = item.split(amount, ctx);

    kiosk.lock(kiosk_cap, policy, new_item);
  }

  public fun merge_items(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    protected_policy: &AresRPG_TransferPolicy<Item>,
    target_item_id: ID,
    items_ids: &mut vector<ID>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let (mut target_item, promise) = kiosk.borrow_val<Item>(kiosk_cap, target_item_id);

    while (!items_ids.is_empty()) {
      let item_id = items_ids.pop_back();
      let item = protected_policy.extract_from_kiosk(
        kiosk,
        kiosk_cap,
        item_id,
        ctx
      );

      target_item.merge(item);
    };

    kiosk.return_val(target_item, promise);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to mint an item
  /// This is used to create items that players win during the gameplay
  /// The function return a promise to make sure the item is locked in the extension
  /// But before it can be augmented with stats and other properties
  public fun admin_mint(
    admin: &AdminCap,
    name: String,
    item_category: String,
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

    emit(ItemMintEvent {
      item_id: object::id(&item),
      kiosk_id: object::id(kiosk)
    });

    place_item_in_extension(kiosk, item, ctx);
  }
}