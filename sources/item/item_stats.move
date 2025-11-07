module aresrpg::item_stats;

use aresrpg::{auth::AuthKey, item::Item};

// This module is responsible for managing the statistics of an item

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

/// The item is stackable, you can't add damages to it
const EItemStackable: u64 = 101;
const EInvalidUpdate: u64 = 102;

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

public struct ItemStatistics has copy, drop, store {
  // All values centered at SHIFT_U16 (32768)
  vitality: u16,
  wisdom: u16,
  strength: u16,
  intelligence: u16,
  chance: u16,
  agility: u16,
  range: u16,
  movement: u16,
  action: u16,
  critical: u16,
  raw_damage: u16,
  critical_chance: u16,
  critical_outcomes: u16,
  earth_resistance: u16,
  fire_resistance: u16,
  water_resistance: u16,
  air_resistance: u16,
}

public struct StatsKey has copy, drop, store {}

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

// The server needs to also be able to create those, for example when creating a new item
public fun protected_new(
  _auth: &AuthKey,
  vitality: u16,
  wisdom: u16,
  strength: u16,
  intelligence: u16,
  chance: u16,
  agility: u16,
  range: u16,
  movement: u16,
  action: u16,
  critical: u16,
  raw_damage: u16,
  critical_chance: u16,
  critical_outcomes: u16,
  earth_resistance: u16,
  fire_resistance: u16,
  water_resistance: u16,
  air_resistance: u16,
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

public fun update_stats(
  _auth: &AuthKey,
  item: &mut Item,
  last_stats: ItemStatistics,
  stats: ItemStatistics,
) {
  if (!item.has_field(StatsKey {})) {
    augment_with_stats(item, last_stats);
  };

  let current_stats = item.borrow_field_mut<StatsKey, ItemStatistics>(StatsKey {});

  assert!(
    last_stats.vitality == current_stats.vitality
    && last_stats.wisdom == current_stats.wisdom
    && last_stats.strength == current_stats.strength
    && last_stats.intelligence == current_stats.intelligence
    && last_stats.chance == current_stats.chance
    && last_stats.agility == current_stats.agility
    && last_stats.range == current_stats.range
    && last_stats.movement == current_stats.movement
    && last_stats.action == current_stats.action
    && last_stats.critical == current_stats.critical
    && last_stats.raw_damage == current_stats.raw_damage
    && last_stats.critical_chance == current_stats.critical_chance
    && last_stats.critical_outcomes == current_stats.critical_outcomes
    && last_stats.earth_resistance == current_stats.earth_resistance
    && last_stats.fire_resistance == current_stats.fire_resistance
    && last_stats.water_resistance == current_stats.water_resistance
    && last_stats.air_resistance == current_stats.air_resistance,
    EInvalidUpdate,
  );

  current_stats.vitality = stats.vitality;
  current_stats.wisdom = stats.wisdom;
  current_stats.strength = stats.strength;
  current_stats.intelligence = stats.intelligence;
  current_stats.chance = stats.chance;
  current_stats.agility = stats.agility;
  current_stats.range = stats.range;
  current_stats.movement = stats.movement;
  current_stats.action = stats.action;
  current_stats.critical = stats.critical;
  current_stats.raw_damage = stats.raw_damage;
  current_stats.critical_chance = stats.critical_chance;
  current_stats.critical_outcomes = stats.critical_outcomes;
  current_stats.earth_resistance = stats.earth_resistance;
  current_stats.fire_resistance = stats.fire_resistance;
  current_stats.water_resistance = stats.water_resistance;
  current_stats.air_resistance = stats.air_resistance;
}

// ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

public(package) fun new(
  vitality: u16,
  wisdom: u16,
  strength: u16,
  intelligence: u16,
  chance: u16,
  agility: u16,
  range: u16,
  movement: u16,
  action: u16,
  critical: u16,
  raw_damage: u16,
  critical_chance: u16,
  critical_outcomes: u16,
  earth_resistance: u16,
  fire_resistance: u16,
  water_resistance: u16,
  air_resistance: u16,
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

public(package) fun augment_with_stats(item: &mut Item, stats: ItemStatistics) {
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

public fun range(self: &ItemStatistics): u16 {
  self.range
}

public fun movement(self: &ItemStatistics): u16 {
  self.movement
}

public fun action(self: &ItemStatistics): u16 {
  self.action
}

public fun critical(self: &ItemStatistics): u16 {
  self.critical
}

public fun raw_damage(self: &ItemStatistics): u16 {
  self.raw_damage
}

public fun critical_chance(self: &ItemStatistics): u16 {
  self.critical_chance
}

public fun critical_outcomes(self: &ItemStatistics): u16 {
  self.critical_outcomes
}

public fun earth_resistance(self: &ItemStatistics): u16 {
  self.earth_resistance
}

public fun fire_resistance(self: &ItemStatistics): u16 {
  self.fire_resistance
}

public fun water_resistance(self: &ItemStatistics): u16 {
  self.water_resistance
}

public fun air_resistance(self: &ItemStatistics): u16 {
  self.air_resistance
}
