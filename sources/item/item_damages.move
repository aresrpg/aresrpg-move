module aresrpg::item_damages;

use aresrpg::{auth::AuthKey, item::Item};
use std::string::String;

// This module is used to store the damages of an item.

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

public struct DamagesKey has copy, drop, store {}

public struct ItemDamages has store, copy, drop {
  from: u16,
  to: u16,
  damage_type: String,
  element: String,
}

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

/// The item is stackable, you can't add damages to it
const EItemStackable: u64 = 101;

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

public fun protected_new(
  _auth: &AuthKey,
  from: u16,
  to: u16,
  damage_type: String,
  element: String,
): ItemDamages {
  ItemDamages {
    from,
    to,
    damage_type,
    element,
  }
}

// ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

public(package) fun new(from: u16, to: u16, damage_type: String, element: String): ItemDamages {
  ItemDamages {
    from,
    to,
    damage_type,
    element,
  }
}

public(package) fun augment_with_damages(item: &mut Item, damages: vector<ItemDamages>) {
  // The item can only have damages if it's not stackable
  assert!(!item.stackable(), EItemStackable);

  item.add_field(DamagesKey {}, damages);
}
