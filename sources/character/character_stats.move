module aresrpg::character_stats {

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

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun add_stat_points(
    self: &mut CharacterStatistics,
    stat_points: u16,
  ) {
    self.available_points = self.available_points + stat_points;
  }

  public(package) fun add_vitality(
    self: &mut CharacterStatistics,
    vitality: u16,
  ) {
    self.use_points(vitality);
    self.vitality = self.vitality + vitality;
  }

  public(package) fun add_wisdom(
    self: &mut CharacterStatistics,
    wisdom: u16,
  ) {
    self.use_points(wisdom);
    self.wisdom = self.wisdom + wisdom;
  }

  public(package) fun add_strength(
    self: &mut CharacterStatistics,
    strength: u16,
) {
    self.use_points(strength);
    self.strength = self.strength + strength;
  }

  public(package) fun add_intelligence(
    self: &mut CharacterStatistics,
    intelligence: u16,
  ) {
    self.use_points(intelligence);
    self.intelligence = self.intelligence + intelligence;
  }

  public(package) fun add_chance(
    self: &mut CharacterStatistics,
    chance: u16,
  ) {
    self.use_points(chance);
    self.chance = self.chance + chance;
  }

  public(package) fun add_agility(
    self: &mut CharacterStatistics,
    agility: u16,
  ) {
    self.use_points(agility);
    self.agility = self.agility + agility;
  }

  public(package) fun reset(self: &mut CharacterStatistics) {
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

  public(package) fun new(): CharacterStatistics {
    CharacterStatistics {
      vitality: 0,
      wisdom: 0,
      strength: 0,
      intelligence: 0,
      chance: 0,
      agility: 0,

      available_points: 0,
    }
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun use_points(self: &mut CharacterStatistics, stat_points: u16) {
    assert!(self.available_points >= stat_points, ENotEnoughStatPoints);

    self.available_points = self.available_points - stat_points;
  }
}