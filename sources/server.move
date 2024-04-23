module aresrpg::server {
  use sui::tx_context::{sender};
  use sui::event;
  use sui::object_bag::{Self, ObjectBag};
  use sui::vec_set::{Self, VecSet};

  use std::string::{String};

  use aresrpg::character::{Self, Character, set_storage_id, remove_storage_id};

  // ====== Types ======

  // Allows admin actions like mutating player data
  public struct AdminCap has key {
    id: UID,
    // keeping track of all created storages, sort of on-chain load balancer
    known_storages: VecSet<ID>
  }

  /// A receipt allowing an user to unlock a character
  public struct CharacterLockReceipt has key {
    id: UID,
    storage_id: ID,
    character_id: ID
  }
  public struct ServerStorage has key, store {
    id: UID,
    characters: ObjectBag
  }

  // ====== Events ======

  public struct Update has copy, drop {
    /// The address of the user impacted by the update
    target: address
  }

  fun init(ctx: &mut TxContext) {
    let storage_uid = object::new(ctx);
    // create the admin cap and insert the first storage
    let admin_cap = AdminCap {
      id: object::new(ctx),
      known_storages: vec_set::singleton(object::uid_to_inner(&storage_uid))
    };
    // create a storage out of the box for ease of use
    let server_storage = ServerStorage {
      id: storage_uid,
      characters: object_bag::new(ctx)
    };

    transfer::transfer(admin_cap, sender(ctx));
    transfer::share_object(server_storage);
  }

  // ====== Accessors ======

  /// Get a read only reference to the storage, anyone can call this
  public fun borrow_character(
    server_storage: &ServerStorage,
    character_id: ID
  ): &Character {
    object_bag::borrow(&server_storage.characters, character_id)
  }

  /// ====== Mutators ======

  /// Create a new storage to balance the load on storage objects
  public fun create_storage(adminCap: &mut AdminCap, ctx: &mut TxContext) {
    let storage_uid = object::new(ctx);
    let storage_id = object::uid_to_inner(&storage_uid);
    let server_storage = ServerStorage {
      id: storage_uid,
      characters: object_bag::new(ctx)
    };

    vec_set::insert(&mut adminCap.known_storages, storage_id);
    transfer::share_object(server_storage);
  }

  /// Lock a character in the server to be used in the game
  public fun lock_character(
    server_storage: &mut ServerStorage,
    character: Character,
    ctx: &mut TxContext
  ) {
    event::emit(Update { target: sender(ctx) });

    let mut character = character;

    set_storage_id(&mut character, object::uid_to_inner(&server_storage.id));

    let character_id = object::id(&character);
    object_bag::add(&mut server_storage.characters, character_id, character);

    transfer::transfer(CharacterLockReceipt {
      id: object::new(ctx),
      character_id,
      storage_id: object::uid_to_inner(&server_storage.id)
    }, sender(ctx));
  }

  /// Unlock a character
  public fun unlock_character(
    server_storage: &mut ServerStorage,
    lock_receipt: CharacterLockReceipt,
    ctx: &mut TxContext
  ): Character {
    event::emit(Update { target: sender(ctx) });

    let CharacterLockReceipt { character_id, id, storage_id: _ } = lock_receipt;

    object::delete(id);
    let mut character = object_bag::remove<ID, Character>(&mut server_storage.characters, character_id);

    remove_storage_id(&mut character);

    return character
  }

  public fun character_set_experience(
    _: &AdminCap,
    server_storage: &mut ServerStorage,
    character_id: ID,
    experience: u64
  ) {
    let character = object_bag::borrow_mut(&mut server_storage.characters, character_id);
    character::set_experience(character, experience);
  }

  public fun character_set_position(
    _: &AdminCap,
    server_storage: &mut ServerStorage,
    character_id: ID,
    position: String
  ) {
    let character = object_bag::borrow_mut(&mut server_storage.characters, character_id);
    character::set_position(character, position);
  }

}