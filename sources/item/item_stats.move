module aresrpg::item_stats {

  // This module is responsible for managing the statistics of an item

  use aresrpg::{
    admin::AdminCap,
    item::Item,
  };

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

/// The item is stackable, you can't add damages to it
const EItemStackable: u64 = 101;

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

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun new(
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
  ): ItemStatistics {
    ItemStatistics {
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
    }
  }

  public(package) fun augment_with_stats(
    item: &mut Item,
    stats: ItemStatistics
  ) {
    // The item can only have stats if it's not stackable
    assert!(!item.stackable(), EItemStackable);

    item.add_field(StatsKey {}, stats);
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun vitality(self: &ItemStatistics): u16 {
    self.vitality
  }

  public fun wisdom(self: &ItemStatistics): u16 {
    self.wisdom
  }

  public fun strength(self: &ItemStatistics): u16 {
    self.strength
  }

  public fun intelligence(self: &ItemStatistics): u16 {
    self.intelligence
  }

  public fun chance(self: &ItemStatistics): u16 {
    self.chance
  }

  public fun agility(self: &ItemStatistics): u16 {
    self.agility
  }

  public fun range(self: &ItemStatistics): u8 {
    self.range
  }

  public fun movement(self: &ItemStatistics): u8 {
    self.movement
  }

  public fun action(self: &ItemStatistics): u8 {
    self.action
  }

  public fun critical(self: &ItemStatistics): u8 {
    self.critical
  }

  public fun raw_damage(self: &ItemStatistics): u16 {
    self.raw_damage
  }

  public fun critical_chance(self: &ItemStatistics): u8 {
    self.critical_chance
  }

  public fun critical_outcomes(self: &ItemStatistics): u8 {
    self.critical_outcomes
  }

  public fun earth_resistance(self: &ItemStatistics): u8 {
    self.earth_resistance
  }

  public fun fire_resistance(self: &ItemStatistics): u8 {
    self.fire_resistance
  }

  public fun water_resistance(self: &ItemStatistics): u8 {
    self.water_resistance
  }

  public fun air_resistance(self: &ItemStatistics): u8 {
    self.air_resistance
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  public fun admin_new(
    admin: &AdminCap,
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
  ): ItemStatistics {
    admin.verify(ctx);

    new(
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
    )
  }

  /// Allow the admin to compose damages on an item
  public fun admin_augment_with_stats(
    admin: &AdminCap,
    item: &mut Item,
    stats: ItemStatistics,
    ctx: &TxContext
  ) {
    admin.verify(ctx);

    augment_with_stats(item, stats);
  }
}