module aresrpg::character {
  use sui::tx_context::{sender};
  use sui::package;
  use sui::display;
  use sui::table::{Self, Table};
  use sui::event;

  use std::string::{Self, utf8, String, to_ascii, from_ascii};
  use std::ascii;

  const ENameTooLong: u64 = 0;
  const ENameTaken: u64 = 1;
  const EInvalidClasse: u64 = 2;
  const EInvalidSex: u64 = 3;
  const EHasWhitespace: u64 = 4;
  const EVersionMismatch: u64 = 5;
  const EExperienceTooLow: u64 = 6;

  const VERSION: u64 = 5;

  public struct Character has key, store {
    id: UID,
    name: String,
    position: String,
    experience: u64,
    classe: String,
    sex: String,
  }

  public struct CharacterNameRegistry has key, store {
    id: UID,
    module_version: u64,
    registry: Table<String, address>,
  }

  public struct AdminCap has key {
    id: UID,
  }

  // ====== Events ======

  public struct Update has copy, drop {
    /// The address of the user impacted by the update
    target: address
  }

  // one time witness
  public struct CHARACTER has drop {}

  fun init(otw: CHARACTER, ctx: &mut TxContext) {
    let name_registry = CharacterNameRegistry {
      id: object::new(ctx),
      module_version: VERSION,
      registry: table::new(ctx),
    };
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
    let admin_cap = AdminCap { id: object::new(ctx) };

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));

    transfer::transfer(admin_cap, sender(ctx));

    transfer::share_object(name_registry);
  }

  // ====== Functions ======

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

  public fun create_character(
    name_registry: &mut CharacterNameRegistry,
    raw_name: String,
    classe: String,
    sex: String,
    ctx: &mut TxContext
  ): Character {
    let name = to_lower_case(raw_name);

    assert!(name_registry.module_version == VERSION, EVersionMismatch);
    assert!(string::length(&name) > 3 && string::length(&name) < 20, ENameTooLong);
    assert!(!table::contains(&name_registry.registry, name), ENameTaken);
    assert!(!contains_whitespace(name), EHasWhitespace);
    assert!(valid_classe(classe), EInvalidClasse);
    assert!(valid_sex(sex), EInvalidSex);

    event::emit(Update { target: sender(ctx) });
    table::add(&mut name_registry.registry, name, sender(ctx));

    Character {
      id: object::new(ctx),
      name,
      position: utf8(b"{\"x\":0,\"y\":0,\"z\":0}"),
      experience: 0,
      classe,
      sex
    }
  }

  public fun delete_character(
    character: Character,
    name_registry: &mut CharacterNameRegistry,
    ctx: &mut TxContext
  ) {
    assert!(name_registry.module_version == VERSION, EVersionMismatch);

    let Character {
      id,
      name,
      position: _,
      experience: _,
      classe: _,
      sex: _,
    } = character;

    event::emit(Update { target: sender(ctx) });
    table::remove(&mut name_registry.registry, name);
    object::delete(id);
  }

  fun to_lower_case(str: String): String {
    let string = to_ascii(str);
    let (mut bytes, mut i) = (ascii::into_bytes(string), 0);

    while (i < vector::length(&bytes)) {
      let byte = vector::borrow_mut(&mut bytes, i);
      if (*byte >= 65u8 && *byte <= 90u8) *byte = *byte + 32u8;
      i = i + 1;
    };

    from_ascii(ascii::string(bytes))
  }

  fun contains_whitespace(str: String): bool {
    let string = to_ascii(str);
    let (mut bytes, mut i) = (ascii::into_bytes(string), 0);

    while (i < vector::length(&bytes)) {
      let byte = vector::borrow_mut(&mut bytes, i);
      if (*byte == 32u8) return true;
      i = i + 1;
    };

    false
  }

  /// Migrate the module to the latest version, this prevent usage of old functions
  /// towards the name registry
  entry fun migrate(
    _: &AdminCap,
    name_registry: &mut CharacterNameRegistry
  ) {
    assert!(name_registry.module_version < VERSION, EVersionMismatch);
    name_registry.module_version = VERSION;
  }

  /// ====== Accessors ======

  public fun character_name(character: &Character): &String {
    &character.name
  }

  public fun character_experience(character: &Character): &u64 {
    &character.experience
  }

  public fun is_name_taken(
    name_registry: &CharacterNameRegistry,
    raw_name: String,
  ) {
    let name = to_lower_case(raw_name);

    assert!(name_registry.module_version == VERSION, EVersionMismatch);
    assert!(!contains_whitespace(name), EHasWhitespace);
    assert!(!table::contains(&name_registry.registry, name), ENameTaken);
  }

  /// ====== Mutators ======

  /// Add experience to a character (package only to prevent public usage)
  public(package) fun set_experience(
    character: &mut Character,
    experience: u64,
  ) {
    assert!(experience > character.experience, EExperienceTooLow);
    character.experience = experience;
  }

  /// Set the position of a character (package only to prevent public usage)
  public(package) fun set_position(
    character: &mut Character,
    position: String,
  ) {
    character.position = position;
  }

}