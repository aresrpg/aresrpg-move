module aresrpg::user {
  use sui::tx_context::{Self, TxContext};
  use sui::object::{Self, UID, ID};
  use sui::transfer;

  use std::string::{Self, String, utf8};

  use aresrpg::storage::{
    Self as ares_storage,
    Storage,
    StorageCap,
    MutationCap
  };

  const ENameTooLong: u64 = 0;

  struct UserProfile has key, store {
    id: UID,
    name: String,
    mastery: u16,
    storage_id: ID,
  }

  public fun create_user_profile(
    name: String,
    storage_id: ID,
    ctx: &mut TxContext
  ): UserProfile {
    assert!(string::length(&name) > 3 && string::length(&name) < 20, ENameTooLong);

    UserProfile {
      id: object::new(ctx),
      name,
      mastery: 0,
      storage_id
    }
  }

  public fun delete_user_profile(profile: UserProfile) {
    let UserProfile { id, mastery: _, name: _, storage_id: _ } = profile;
    object::delete(id);
  }

  public fun store_profile(
    storage_cap: &StorageCap,
    storage: &mut Storage,
    profile: UserProfile,
  ) {
    ares_storage::store(storage_cap, storage, utf8(b"profile"), profile);
  }

  public entry fun withdraw_profile(
    storage_cap: &StorageCap,
    storage: &mut Storage,
    ctx: &mut TxContext,
  ) {
    let sender = tx_context::sender(ctx);
    let profile = ares_storage::remove<UserProfile>(storage_cap, storage, utf8(b"profile"));

    transfer::transfer(profile, sender);
  }

  /// ====== Accessors ======

  public fun user_mastery(profile: &UserProfile): u16 {
    profile.mastery
  }

  public fun user_name(profile: &UserProfile): &String {
    &profile.name
  }

  /// ====== Mutators ======

  public fun set_user_mastery(
    mutation_cap: &MutationCap,
    storage: &mut Storage,
    mastery: u16,
  ) {
    let user_profile = ares_storage::borrow_mut<UserProfile>(
      mutation_cap,
      storage,
      utf8(b"profile")
    );

    user_profile.mastery = mastery;
  }

  public fun set_user_name(
    mutation_cap: &MutationCap,
    storage: &mut Storage,
    name: String,
  ) {
    let user_profile = ares_storage::borrow_mut<UserProfile>(
      mutation_cap,
      storage,
      utf8(b"profile")
    );

    user_profile.name = name;
  }
}