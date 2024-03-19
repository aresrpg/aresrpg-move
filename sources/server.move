module aresrpg::server {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::event;
  use sui::object::{Self, UID, ID};
  use sui::object_bag::{Self, ObjectBag};

  use aresrpg::character::{Self, Character};

  // ====== Types ======

  // Allows admin actions like mutating player data
  struct AdminCap has key { id: UID }

  /// A receipt allowing an user to unlock a character
  struct CharacterLockReceipt has key {
    id: UID,
    character_id: ID
  }

  struct ServerStorage has key, store {
    id: UID,
    characters: ObjectBag
  }

  // ====== Events ======

  struct Update has copy, drop {
    /// The address of the user impacted by the update
    for: address
  }

  fun init(ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    let admin_cap = AdminCap { id: object::new(ctx) };
    let server_storage = ServerStorage {
      id: object::new(ctx),
      characters: object_bag::new(ctx)
    };

    transfer::transfer(admin_cap, sender);
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

  /// Lock a character in the server to be used in the game
  public fun lock_character(
    server_storage: &mut ServerStorage,
    character: Character,
    ctx: &mut TxContext
  ) {
    event::emit(Update { for: tx_context::sender(ctx) });

    let character_id = object::id(&character);
    object_bag::add(&mut server_storage.characters, character_id, character);

    transfer::transfer(CharacterLockReceipt {
      id: object::new(ctx),
      character_id
    }, tx_context::sender(ctx));
  }

  /// Unlock a character
  public fun unlock_character(
    server_storage: &mut ServerStorage,
    lock_receipt: CharacterLockReceipt,
    ctx: &mut TxContext
  ): Character {
    event::emit(Update { for: tx_context::sender(ctx) });

    let CharacterLockReceipt { character_id, id } = lock_receipt;

    object::delete(id);
    object_bag::remove<ID, Character>(&mut server_storage.characters, character_id)
  }

  public fun character_add_experience(
    _: &AdminCap,
    server_storage: &mut ServerStorage,
    character_id: ID,
    experience: u64
  ) {
    let character = object_bag::borrow_mut(&mut server_storage.characters, character_id);
    character::add_experience(character, experience);
  }

}