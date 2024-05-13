module aresrpg::item_damages {

  // This module is used to store the damages of an item.

  use std::string::{String};

  use aresrpg::{
    admin::AdminCap,
    item::Item,
  };

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct DamagesKey has copy, drop, store {}


  public struct ItemDamages has store, copy, drop {
    from: u16,
    to: u16,
    damage_type: String,
    element: String
  }

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

/// The item is stackable, you can't add damages to it
const EItemStackable: u64 = 1;

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Create a new damage object, used by the admin to compose damages on an item
  /// Through creating multiple ones and adding them to a new vector in a subsequent instruction
  /// There is technically no need for an admincap here but let's keep it for consistency
  public fun admin_new(
    admin: &AdminCap,
    from: u16,
    to: u16,
    damage_type: String,
    element: String,
    ctx: &TxContext
  ): ItemDamages {
    admin.verify(ctx);
    ItemDamages {
      from,
      to,
      damage_type,
      element
    }
  }

  /// Allow the admin to compose damages on an item
  public fun admin_augment_with_damages(
    admin: &AdminCap,
    item: &mut Item,
    damages: vector<ItemDamages>,
    ctx: &TxContext
  ) {
    admin.verify(ctx);

    // The item can only have damages if it's not stackable
    assert!(!item.stackable(), EItemStackable);

    item.add_field(DamagesKey {}, damages);
  }
}