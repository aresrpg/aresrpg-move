module aresrpg::item_stats {

  // This module is responsible for managing the statistics of an item

  use aresrpg::{
    admin::AdminCap,
    item::Item,
  };

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct ItemStatistics has store, copy, drop {
    vitality: u16,
    wisdom: u16,
    strength: u16,
    intelligence: u16,
    chance: u16,
    agility: u16,
    range: u8,
    movement: u8,
    action: u8,
    critical: u8,
    critical_chance: u8,
    critical_outcomes: u8,
  }

  public struct StatsKey has copy, drop, store {}

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to compose damages on an item
  public fun admin_augment_with_damages(
    _admin: &AdminCap,
    item: &mut Item,

    vitality: u16,
    wisdom: u16,
    strength: u16,
    intelligence: u16,
    chance: u16,
    agility: u16,
    range: u8,
    movement: u8,
    action: u8,
    critical: u8,
    critical_chance: u8,
    critical_outcomes: u8,
  ) {
    item.add_field(StatsKey {}, ItemStatistics {
      vitality,
      wisdom,
      strength,
      intelligence,
      chance,
      agility,
      range,
      movement,
      action,
      critical,
      critical_chance,
      critical_outcomes,
    });
  }
}