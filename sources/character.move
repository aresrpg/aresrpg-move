module aresrpg::character {
  use sui::tx_context::{sender, TxContext};
  use sui::object::{Self, UID};
  use sui::event;
  use sui::transfer;
  use sui::package;
  use sui::display;
  use sui::table::{Self, Table};

  use std::string::{Self, utf8, String, to_ascii, from_ascii};

  use suitears::ascii_utils::{to_lower_case};

  const ENameTooLong: u64 = 0;
  const ENameTaken: u64 = 1;

  friend aresrpg::server;

  struct Character has key, store {
    id: UID,
    name: String,
    position: String,
    experience: u64,
    classe: String,
    sex: String,
  }

  struct CharacterNameRegistry has key, store {
    id: UID,
    registry: Table<String, address>,
  }

  // one time witness
  struct CHARACTER has drop {}

  fun init(otw: CHARACTER, ctx: &mut TxContext) {
    let name_registry = CharacterNameRegistry {
      id: object::new(ctx),
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
        utf8(b"https://aresrpg.world/classe/{classe}"),
        utf8(b"https://aresrpg.world/classe/{classe}_{sex}.png"),
        utf8(b"Character part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
    ];

    let publisher = package::claim(otw, ctx);
    let display = display::new_with_fields<Character>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));

    transfer::share_object(name_registry);
  }

  // ====== Events ======

  struct Update has copy, drop {
    /// The address of the user impacted by the update
    for: address
  }

  // ====== Functions ======

  public fun create_character(
    name_registry: &mut CharacterNameRegistry,
    raw_name: String,
    classe: String,
    sex: String,
    ctx: &mut TxContext
  ): Character {
    let ascii_name = to_ascii(raw_name);
    let lower_case_name = to_lower_case(ascii_name);
    let utf8_name = from_ascii(lower_case_name);

    assert!(string::length(&utf8_name) > 3 && string::length(&utf8_name) < 20, ENameTooLong);
    assert!(!table::contains(&name_registry.registry, utf8_name), ENameTaken);

    event::emit(Update { for: sender(ctx) });
    table::add(&mut name_registry.registry, utf8_name, sender(ctx));

    Character {
      id: object::new(ctx),
      name: utf8_name,
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
    let Character {
      id,
      name,
      position: _,
      experience: _,
      classe: _,
      sex: _,
    } = character;

    event::emit(Update { for: sender(ctx) });
    table::remove(&mut name_registry.registry, name);
    object::delete(id);
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
    name: String,
  ) {
    let ascii_name = to_ascii(name);
    let lower_case_name = to_lower_case(ascii_name);
    let utf8_name = from_ascii(lower_case_name);

    assert!(!table::contains(&name_registry.registry, utf8_name), ENameTaken);
  }

  /// ====== Mutators ======

  /// Add experience to a character (friend only to prevent public usage)
  public(friend) fun add_experience(
    character: &mut Character,
    experience: u64,
  ) {
    character.experience = character.experience + experience;
  }
}