module aresrpg::item_damages {

  use std::string::{String};

  use aresrpg::admin::AdminCap;

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  public struct ItemDamages has store, copy, drop {
    from: u16,
    to: u16,
    damage_type: String,
    element: String
  }

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

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
}