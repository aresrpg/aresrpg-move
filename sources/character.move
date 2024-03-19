module aresrpg::character {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{Self, UID};
  use sui::event;
  use sui::transfer;
  use sui::vec_set::{Self, VecSet};

  use std::string::{Self, String};

  const ENameTooLong: u64 = 0;
  const ENameTaken: u64 = 1;

  friend aresrpg::server;

  struct Character has key, store {
    id: UID,
    name: String,
    experience: u64,
  }

  struct CharacterNameRegistry has key, store {
    id: UID,
    registry: VecSet<String>
  }

  fun init(ctx: &mut TxContext) {
    let name_registry = CharacterNameRegistry {
      id: object::new(ctx),
      registry: vec_set::empty()
    };

    transfer::share_object(name_registry);
  }

  // ====== Events ======

  struct Update has copy, drop {
    /// The address of the user impacted by the update
    for: address
  }

  public fun create_character(
    name: String,
    name_registry: &mut CharacterNameRegistry,
    ctx: &mut TxContext
  ): Character {
    assert!(string::length(&name) > 3 && string::length(&name) < 20, ENameTooLong);
    assert!(!vec_set::contains(&name_registry.registry, &name), ENameTaken);

    event::emit(Update { for: tx_context::sender(ctx) });

    vec_set::insert(&mut name_registry.registry, name);

    Character {
      id: object::new(ctx),
      name,
      experience: 0,
    }
  }

  public fun delete_character(
    character: Character,
    name_registry: &mut CharacterNameRegistry,
    ctx: &mut TxContext
  ) {
    let Character { id, name, experience: _ } = character;

    event::emit(Update { for: tx_context::sender(ctx) });
    vec_set::remove(&mut name_registry.registry, &name);
    object::delete(id);
  }

  /// ====== Accessors ======

  public fun character_name(character: &Character): &String {
    &character.name
  }

  public fun character_experience(character: &Character): &u64 {
    &character.experience
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