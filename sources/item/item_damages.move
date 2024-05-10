module aresrpg::item_damages {

  // This module is used to store the damages of an item.

  use std::string::{String};

  use aresrpg::{
    admin::AdminCap,
    item::Item,
  };

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct DamagesKey has copy, drop, store {}

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  public struct ItemDamages has store, copy, drop {
    from: u16,
    to: u16,
    damage_type: String,
    element: String
  }

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Create a new damage object, used by the admin to compose damages on an item
  /// Through creating multiple ones and adding them to a new vector in a subsequent instruction
  /// There is technically no need for an admincap here but let's keep it for consistency
  public fun admin_new(
    _admin: &AdminCap,
    from: u16,
    to: u16,
    damage_type: String,
    element: String
  ): ItemDamages {
    ItemDamages {
      from,
      to,
      damage_type,
      element
    }
  }

  /// Allow the admin to compose damages on an item
  public fun admin_augment_with_damages(
    _admin: &AdminCap,
    item: &mut Item,
    damages: vector<ItemDamages>
  ) {
    item.add_field(DamagesKey {}, damages);
  }
}