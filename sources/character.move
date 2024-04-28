module aresrpg::character {
  use sui::{
    tx_context::{sender},
    package,
    display,
    event,
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
  const EExperienceTooLow: u64 = 6;

  public struct Character has key, store {
    id: UID,
    name: String,
    position: String,
    experience: u64,
    classe: String,
    sex: String,
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
      sex
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
    } = character;

    name_registry.remove_name(name);
    event::emit(Update { target: sender(ctx) });
    object::delete(id);
  }

  /// Add experience to a character
  public fun set_experience(
    character: &mut Character,
    _admin: &AdminCap,
    experience: u64,
  ) {
    assert!(experience > character.experience, EExperienceTooLow);
    character.experience = experience;
  }

  /// Set the position of a character
  public fun set_position(
    character: &mut Character,
    _admin: &AdminCap,
    position: String,
  ) {
    character.position = position;
  }

  // ╔════════════════ [ Read ] ════════════════════════════════════════════ ]

  public fun character_name(character: &Character): &String {
    &character.name
  }

  public fun character_experience(character: &Character): &u64 {
    &character.experience
  }
}