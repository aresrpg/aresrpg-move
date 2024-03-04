module aresrpg::storage {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{Self, UID, ID};
  use sui::dynamic_object_field as ofield;
  use sui::transfer;
  use sui::vec_set::{Self, VecSet};

  use std::string::String;

  /// MutationCap is created once and allows the caller to mutate any storage
  struct MutationCap has key { id: UID }

  /// Allows storing and removing data from a specific storage
  struct StorageCap has key {
    id: UID,
    storage_id: ID,
    stored: VecSet<String>
  }

  struct Storage has key, store { id: UID }

  /// the provided StorageCap does not match the storage
  const ESTorageCapMismatch: u64 = 1;

  fun init(ctx: &mut TxContext) {
    // send the mutation cap to the deployer
    let mutation_cap = MutationCap { id: object::new(ctx) };
    transfer::transfer(mutation_cap, tx_context::sender(ctx));
  }

  /// Create a new storage and the caps to interact with it
  public fun create(ctx: &mut TxContext) {
    let storage_id = object::new(ctx);

    let storage_cap = StorageCap {
      id: object::new(ctx),
      storage_id: object::uid_to_inner(&storage_id),
      stored: vec_set::empty()
    };

    let storage = Storage { id: storage_id };
    let sender = tx_context::sender(ctx);

    transfer::share_object(storage);
    transfer::transfer(storage_cap, sender);
  }

  /// Get a read only reference to the storage, anyone can call this
  public fun borrow<T: key + store>(
    storage: &mut Storage,
    key: ID
  ): &T {
    ofield::borrow(&storage.id, key)
  }

  public fun has(
    storage: &mut Storage,
    key: ID
  ): bool {
    ofield::exists_(&storage.id, key)
  }

  /// Get a mutable reference to the storage, only the mutationCap can call this
  public fun borrow_mut<T: key + store>(
    _: &MutationCap,
    storage: &mut Storage,
    key: ID,
  ): &mut T {
    ofield::borrow_mut(&mut storage.id, key)
  }

  /// Store data in the storage, only the storageCap can call this
  public fun store<T: key + store>(
    storageCap: &mut StorageCap,
    storage: &mut Storage,
    key: String,
    value: T,
  ) {
    assert!(&storageCap.storage_id == &object::uid_to_inner(&storage.id), ESTorageCapMismatch);

    vec_set::insert(&mut storageCap.stored, key);
    ofield::add(&mut storage.id, key, value)
  }

  /// Remove data from the storage, only the storageCap can call this
  public fun remove<T: key + store>(
    storageCap: &mut StorageCap,
    storage: &mut Storage,
    key: String,
  ): T {
    assert!(&storageCap.storage_id == &object::uid_to_inner(&storage.id), ESTorageCapMismatch);

    vec_set::remove(&mut storageCap.stored, &key);
    ofield::remove(&mut storage.id, key)
  }
}