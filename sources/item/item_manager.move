module aresrpg::item_manager {

  // This module is responsible for managing items (minting, transfering, etc.)

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::TransferPolicy,
    kiosk_extension
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
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EExtensionNotInstalled: u64 = 1;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]


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

    kiosk.lock(kiosk_cap, policy, item);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to mint an item
  /// and place it in the aresrpg extension of a given Kiosk
  /// The AresRPG extension must be installed on the Kiosk
  /// This is used to create items that players win during the gameplay
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
}