module aresrpg::character_stats {

  // This module is responsible for managing the character stats

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    event::emit
  };

  use aresrpg::{
    character::Character,
    version::Version,
    admin::AdminCap,
    protected_policy::AresRPG_TransferPolicy,
    item::Item,
  };

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

public struct StatsKey has copy, drop, store {}

// ╔════════════════ [ Events ] ════════════════════════════════════════════ ]

public struct StatsResetEvent has copy, drop {
  character_id: ID,
}

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const ENotEnoughStatPoints: u64 = 1;

  public struct CharacterStatistics has store {
    vitality: u16,
    wisdom: u16,
    strength: u16,
    intelligence: u16,
    chance: u16,
    agility: u16,

    available_points: u16,
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Add stat points to the character.
  public fun admin_add_stat_points(
    admin: &AdminCap,
    stat_points: u16,
    character: &mut Character,
    ctx: &TxContext
  ) {
    admin.verify(ctx);

    let stats = borrow_stats_mut(character);
    stats.available_points = stats.available_points + stat_points;
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Reset the character stats using the orb of reset.
  /// That kind of actions happens when the character isn't selected
  /// We still need the kiosk to access the orb item and destroy it
  public fun reset_character_stats(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    character: &mut Character,
    item_id: ID,
    policy: &AresRPG_TransferPolicy<Item>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let item = policy.extract_from_kiosk<Item>(
      kiosk,
      cap,
      item_id,
      ctx
    );

    item.assert_item_type(b"reset_orb");
    item.destroy();

    let stats = borrow_stats_mut(character);
    stats.reset();

    emit(StatsResetEvent { character_id: object::id(character) });
  }

  /// Add stats to the character if there are enough available points
  public fun add_vitality(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.vitality = stats.vitality + amount;
  }

  public fun add_wisdom(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.wisdom = stats.wisdom + amount;
  }

  public fun add_strength(
    character: &mut Character,
    amount: u16,
    version: &Version,
) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.strength = stats.strength + amount;
  }

  public fun add_intelligence(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.intelligence = stats.intelligence + amount;
  }

  public fun add_chance(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.chance = stats.chance + amount;
  }

  public fun add_agility(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();

    let stats = borrow_stats_mut(character);

    stats.use_points(amount);
    stats.agility = stats.agility + amount;
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  /// Add the character stats object to the character
  public(package) fun add_to_character(character: &mut Character) {
    character.add_field(StatsKey {}, CharacterStatistics {
      vitality: 0,
      wisdom: 0,
      strength: 0,
      intelligence: 0,
      chance: 0,
      agility: 0,

      available_points: 0,
    });
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun use_points(self: &mut CharacterStatistics, stat_points: u16) {
    assert!(self.available_points >= stat_points, ENotEnoughStatPoints);

    self.available_points = self.available_points - stat_points;
  }

  fun reset(self: &mut CharacterStatistics) {
    self.available_points = self.available_points
      + self.vitality
      + self.wisdom
      + self.strength
      + self.intelligence
      + self.chance
      + self.agility;

    self.vitality = 0;
    self.wisdom = 0;
    self.strength = 0;
    self.intelligence = 0;
    self.chance = 0;
    self.agility = 0;
  }

  fun borrow_stats_mut(character: &mut Character): &mut CharacterStatistics {
    character.borrow_field_mut<StatsKey, CharacterStatistics>(StatsKey {})
  }
}