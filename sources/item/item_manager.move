module aresrpg::item_manager {

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::TransferPolicy,
    kiosk_extension
  };

  use std::string::{String};

  use aresrpg::{
    item::{Self as a_item, Item},
    item_stats::{Self, ItemStatistics},
    item_damages::{Self, ItemDamages},
    admin::AdminCap,
    version::Version,
    extension::{
      AresRPG,
      place_item_in_extension,
      take_item_from_extension,
    },
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EExtensionNotInstalled: u64 = 1;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct StatsKey has copy, drop, store {}
  public struct DamagesKey has copy, drop, store {}

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Allows a kiosk owner to withdraw items from the extention to their kiosk.
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

    kiosk.lock(kiosk_cap, policy, item);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to mint an item
  /// and place it in the aresrpg extension of a given Kiosk
  /// The AresRPG extension must be installed on the Kiosk
  public fun admin_mint(
    _admin: &AdminCap,
    kiosk: &mut Kiosk,
    name: String,
    item_category: String,
    item_type: String,
    level: u8,
    ctx: &mut TxContext
  ): ID {
    assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

    let item = a_item::new(
      name,
      item_category,
      item_type,
      level,
      ctx
    );

    let item_id = object::id(&item);

    place_item_in_extension(kiosk, item, ctx);

    item_id
  }

  public fun admin_augment_with_stats(
    _admin: &AdminCap,
    item: &mut Item,
    stats: ItemStatistics
  ) {
    item.add_field(StatsKey {}, stats);
  }

  /// Allow the admin to compose damages on an item
  /// this function can be called multiple times to add multiple damages
  public fun admin_augment_with_damages(
    _admin: &AdminCap,
    item: &mut Item,
    damages: vector<ItemDamages>
  ) {
    item.add_field(DamagesKey {}, damages);
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun clone_item(
    item: &Item,
    ctx: &mut TxContext
  ): Item {
    let mut new_item = item.clone(ctx);

    new_item.add_field(StatsKey {}, *borrow_stats(item));
    new_item.add_field(DamagesKey {}, *borrow_damages(item));

    new_item
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun borrow_stats(item: &Item): &ItemStatistics {
    item.borrow_field<StatsKey, ItemStatistics>(StatsKey {})
  }

  fun borrow_damages(item: &Item): &vector<ItemDamages> {
    item.borrow_field<DamagesKey, vector<ItemDamages>>(DamagesKey {})
  }
}