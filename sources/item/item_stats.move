module aresrpg::item_stats {

  use aresrpg::admin::AdminCap;

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

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

// ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  public fun admin_new(
    _admin: &AdminCap,
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
      critical_chance,
      critical_outcomes,
    }
  }
}