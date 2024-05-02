module aresrpg::character {
  use sui::{
    tx_context::{sender},
    package,
    display,
    event,
    dynamic_field as dfield,
  };

  use std::string::{utf8, String};

  use aresrpg::{
    registry::{NameRegistry},
    string::{to_lower_case},
    admin::{AdminCap},
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EInvalidClasse: u64 = 2;
  const EInvalidSex: u64 = 3;
  const ENotEnoughStatPoints: u64 = 4;
  const EExperienceTooLow: u64 = 6;

  public struct Character has key, store {
    id: UID,
    name: String,
    classe: String,
    sex: String,

    // those can be mutated by the admin
    position: String,
    experience: u32,
    health: u16,
    selected: bool,
    soul: u8,
    available_stat_points: u16,

    // stats, can be mutated by the user (in exchange for stats points)
    vitality: u16,
    wisdom: u16,
    strength: u16,
    intelligence: u16,
    chance: u16,
    agility: u16,
  }

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct Update has copy, drop {
    /// The address of the user impacted by the update
    target: address
  }

  // one time witness
  public struct CHARACTER has drop {}

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

  fun init(otw: CHARACTER, ctx: &mut TxContext) {
    let keys = vector[
        utf8(b"name"),
        utf8(b"link"),
        utf8(b"image_url"),
        utf8(b"description"),
        utf8(b"project_url"),
    ];

    let values = vector[
        utf8(b"{name}"),
        utf8(b"https://app.aresrpg.world"),
        utf8(b"https://raw.githubusercontent.com/aresrpg/aresrpg-dapp/master/src/assets/classe/{classe}_{sex}.jpg"),
        utf8(b"Character part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Character>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
  }

  fun valid_classe(classe: String): bool {
    let classes = vector[
      utf8(b"sram"),
      utf8(b"iop"),
    ];

    vector::contains(&classes, &classe)
  }

  fun valid_sex(sex: String): bool {
    let sexes = vector[
      utf8(b"male"),
      utf8(b"female"),
    ];

    vector::contains(&sexes, &sex)
  }

  /// Create a new character, and add it to the name registry
  /// this function can only be called by the package
  /// so the user must go through the aresrpg::aresrpg module
  public(package) fun create(
    name_registry: &mut NameRegistry,
    raw_name: String,
    classe: String,
    sex: String,
    ctx: &mut TxContext
  ): Character {
    assert!(valid_classe(classe), EInvalidClasse);
    assert!(valid_sex(sex), EInvalidSex);

    let name = to_lower_case(raw_name);

    name_registry.add_name(name, ctx);

    event::emit(Update { target: sender(ctx) });

    Character {
      id: object::new(ctx),
      name,
      position: utf8(b"{\"x\":0,\"y\":0,\"z\":0}"),
      experience: 0,
      classe,
      sex,
      health: 30,
      selected: false,
      soul: 100,
      vitality: 0,
      wisdom: 0,
      strength: 0,
      intelligence: 0,
      chance: 0,
      agility: 0,
      available_stat_points: 0,
    }
  }

  public(package) fun delete(
    character: Character,
    name_registry: &mut NameRegistry,
    ctx: &TxContext
  ) {
    let Character {
      id,
      name,
      position: _,
      experience: _,
      classe: _,
      sex: _,
      health: _,
      selected: _,
      soul: _,
      vitality: _,
      wisdom: _,
      strength: _,
      intelligence: _,
      chance: _,
      agility: _,
      available_stat_points: _,
    } = character;

    name_registry.remove_name(name);
    event::emit(Update { target: sender(ctx) });
    object::delete(id);
  }

  // ╔════════════════ [ Mutated by admin ] ═

  /// Add experience to a character
  public fun set_experience(
    self: &mut Character,
    _admin: &AdminCap,
    experience: u32,
  ) {
    assert!(experience > self.experience, EExperienceTooLow);
    self.experience = experience;
  }

  /// Set the position of a character
  public fun set_position(
    self: &mut Character,
    _admin: &AdminCap,
    position: String,
  ) {
    self.position = position;
  }

  public fun set_health(
    self: &mut Character,
    _admin: &AdminCap,
    health: u16,
  ) {
    self.health = health;
  }

  public fun set_soul(
    self: &mut Character,
    _admin: &AdminCap,
    soul: u8,
  ) {
    self.soul = soul;
  }

  public fun set_available_stat_points(
    self: &mut Character,
    _admin: &AdminCap,
    available_stat_points: u16,
  ) {
    self.available_stat_points = available_stat_points;
  }

  fun use_stat_points(self: &mut Character, stat_points: u16) {
    assert!(self.available_stat_points >= stat_points, ENotEnoughStatPoints);

    self.available_stat_points = self.available_stat_points - stat_points;
  }

  // ╔════════════════ [ Mutated by player ] ═

  public fun add_vitality(self: &mut Character, vitality: u16) {
    use_stat_points(self, vitality);
    self.vitality = self.vitality + vitality;
  }

  public fun add_wisdom(self: &mut Character, wisdom: u16) {
    use_stat_points(self, wisdom);
    self.wisdom = self.wisdom + wisdom;
  }

  public fun add_strength(self: &mut Character, strength: u16) {
    use_stat_points(self, strength);
    self.strength = self.strength + strength;
  }

  public fun add_intelligence(self: &mut Character, intelligence: u16) {
    use_stat_points(self, intelligence);
    self.intelligence = self.intelligence + intelligence;
  }

  public fun add_chance(self: &mut Character, chance: u16) {
    use_stat_points(self, chance);
    self.chance = self.chance + chance;
  }

  public fun add_agility(self: &mut Character, agility: u16) {
    use_stat_points(self, agility);
    self.agility = self.agility + agility;
  }

  // others

  public(package) fun set_selected(self: &mut Character, selected: bool) {
    self.selected = selected;
  }

  public(package) fun set_kiosk_id(self: &mut Character, kiosk_id: ID) {
    dfield::add(&mut self.id, b"kiosk_id", kiosk_id);
  }

  public(package) fun remove_kiosk_id(self: &mut Character) {
    dfield::remove<vector<u8>, ID>(&mut self.id, b"kiosk_id");
  }

  // ╔════════════════ [ Read ] ════════════════════════════════════════════ ]

  public fun inner_id(self: &Character): ID {
    self.id.to_inner()
  }
}