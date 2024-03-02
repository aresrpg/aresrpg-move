module aresrpg::storage {
  use std::string::String;

  use sui::tx_context::{TxContext};
  use sui::object::{Self, UID, ID};
  use sui::object_bag::{Self, ObjectBag};
  use sui::transfer;

  /// Allows mutating data in the storage
  struct MutationCap has key, store { id: UID, storage_id: ID }

  /// Allows storing and removing data from the storage
  struct StorageCap has key, store { id: UID, storage_id: ID  }

  struct Storage has key, store {
    id: UID,
    data: ObjectBag
  }

  /// the provided MutationCap does not match the storage
  const EMutationCapMismatch: u64 = 0;
  /// the provided StorageCap does not match the storage
  const ESTorageCapMismatch: u64 = 1;

  /// Create a new storage, this is called by an user, and point towards a Server entity
  public fun create(ctx: &mut TxContext): (MutationCap, StorageCap, ID) {
    let storage_id = object::new(ctx);
    let storage_id_str = object::uid_to_inner(&storage_id);

    let mutation_cap = MutationCap {
      id: object::new(ctx),
      storage_id: object::uid_to_inner(&storage_id)
    };

    let storage_cap = StorageCap {
      id: object::new(ctx),
      storage_id: object::uid_to_inner(&storage_id)
    };

    let storage = Storage {
      id: storage_id,
      data: object_bag::new(ctx)
    };

    transfer::share_object(storage);

    (mutation_cap, storage_cap, storage_id_str)
  }

  /// Get a read only reference to the storage, anyone can call this
  public fun borrow<T: key + store>(
    storage: &Storage,
    key: String
  ): &T {
    object_bag::borrow<String, T>(&storage.data, key)
  }

  public fun has(
    storage: &Storage,
    key: String
  ): bool {
    object_bag::contains(&storage.data, key)
  }

  /// Get a mutable reference to the storage, only the mutationCap can call this
  public fun borrow_mut<T: key + store>(
    mutationCap: &MutationCap,
    storage: &mut Storage,
    key: String,
  ): &mut T {
    assert!(&mutationCap.storage_id == &object::uid_to_inner(&storage.id), EMutationCapMismatch);

    object_bag::borrow_mut<String, T>(&mut storage.data, key)
  }

  /// Store data in the storage, only the storageCap can call this
  public fun store<T: key + store>(
    storageCap: &StorageCap,
    storage: &mut Storage,
    key: String,
    value: T,
  ) {
    assert!(&storageCap.storage_id == &object::uid_to_inner(&storage.id), ESTorageCapMismatch);

    object_bag::add(&mut storage.data, key, value)
  }

  /// Remove data from the storage, only the storageCap can call this
  public fun remove<T: key + store>(
    storageCap: &StorageCap,
    storage: &mut Storage,
    key: String,
  ): T {
    assert!(&storageCap.storage_id == &object::uid_to_inner(&storage.id), ESTorageCapMismatch);

    object_bag::remove(&mut storage.data, key)
  }
}