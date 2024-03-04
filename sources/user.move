module aresrpg::user {
  use sui::tx_context::{TxContext};
  use sui::object::{Self, UID, ID};
  use sui::event;

  use std::string::{Self, String};

  use aresrpg::storage::{
    Self as ares_storage,
    Storage,
    MutationCap
  };

  const ENameTooLong: u64 = 0;

  struct UserProfile has key, store {
    id: UID,
    name: String,
    mastery: u16,
  }

  // ====== Events ======

  struct UserUpdate has copy, drop {}

  public fun create_user_profile(
    name: String,
    ctx: &mut TxContext
  ): UserProfile {
    assert!(string::length(&name) > 3 && string::length(&name) < 20, ENameTooLong);

    event::emit(UserUpdate {});

    UserProfile {
      id: object::new(ctx),
      name,
      mastery: 0,
    }
  }

  public fun delete_user_profile(profile: UserProfile) {
    let UserProfile { id, mastery: _, name: _ } = profile;
    event::emit(UserUpdate {});
    object::delete(id);
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
    profile_id: ID,
    mastery: u16,
  ) {
    let user_profile = ares_storage::borrow_mut<UserProfile>(
      mutation_cap,
      storage,
      profile_id
    );

    user_profile.mastery = mastery;
  }

  public fun set_user_name(
    mutation_cap: &MutationCap,
    storage: &mut Storage,
    profile_id: ID,
    name: String,
  ) {
    let user_profile = ares_storage::borrow_mut<UserProfile>(
      mutation_cap,
      storage,
      profile_id
    );

    user_profile.name = name;
  }
}