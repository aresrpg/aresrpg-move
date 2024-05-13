module aresrpg::item_stats {

  // This module is responsible for managing the statistics of an item

  use aresrpg::{
    admin::AdminCap,
    item::Item,
  };

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

/// The item is stackable, you can't add damages to it
const EItemStackable: u64 = 1;

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
    raw_damage: u16,
    critical_chance: u8,
    critical_outcomes: u8,

    earth_resistance: u8,
    fire_resistance: u8,
    water_resistance: u8,
    air_resistance: u8,
  }

  public struct StatsKey has copy, drop, store {}

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow the admin to compose damages on an item
  public fun admin_augment_with_stats(
    admin: &AdminCap,
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
    raw_damage: u16,
    critical_chance: u8,
    critical_outcomes: u8,

    earth_resistance: u8,
    fire_resistance: u8,
    water_resistance: u8,
    air_resistance: u8,

    ctx: &TxContext
  ) {
    admin.verify(ctx);

    // The item can only have stats if it's not stackable
    assert!(!item.stackable(), EItemStackable);

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
      raw_damage,
      critical_chance,
      critical_outcomes,
      earth_resistance,
      fire_resistance,
      water_resistance,
      air_resistance,
    });
  }
}