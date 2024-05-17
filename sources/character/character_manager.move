module aresrpg::character_manager {

  // This module is responsible for managing the characters.
  // It is the entry point for creating, deleting, and modifying characters.

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::{TransferPolicy},
    kiosk_extension,
    event::emit
  };

  use std::string::String;

  use aresrpg::{
    character::{Self as a_character, Character},
    character_stats,
    character_registry::{NameRegistry},
    extension::{
      Self,
      AresRPG,
      place_character_in_extension,
      take_character_from_extension,
    },
    protected_policy::AresRPG_TransferPolicy,
    version::Version,
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EInventoryNotEmpty: u64 = 1;

  // ╔════════════════ [ Events ] ════════════════════════════════════════════ ]

  public struct CharacterCreateEvent has copy, drop {
    character_id: ID
  }

  public struct CharacterSelectEvent has copy, drop {
    character_id: ID,
    kiosk_id: ID
  }

  public struct CharacterUnselectEvent has copy, drop {
    character_id: ID,
    kiosk_id: ID
  }

  public struct CharacterDeleteEvent has copy, drop {
    character_id: ID
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Create a character and lock it in the kiosk.
  /// Returns the ID of the character for chaining.
  public fun create_and_lock_character(
    kiosk: &mut Kiosk,
    kiosk_owner_cap: &KioskOwnerCap,
    name_registry: &mut NameRegistry,
    policy: &TransferPolicy<Character>,
    raw_name: String,
    classe: String,
    sex: String,
    version: &Version,
    ctx: &mut TxContext,
  ): ID {
    version.assert_latest();

    let mut character = a_character::new(
      name_registry,
      raw_name,
      classe,
      sex,
      ctx,
    );

    // Add the stats ability
    // Instead of adding more fields and grow the complexity of the character itself
    // we add those additional abilities on top of it to make it more modular.
    character_stats::add_to_character(&mut character);

    let character_id = object::id(&character);

    kiosk.lock<Character>(kiosk_owner_cap, policy, character);

    if(!kiosk_extension::is_installed<AresRPG>(kiosk)) {
      extension::install(kiosk, kiosk_owner_cap, version, ctx);
    };

    if(!kiosk_extension::is_enabled<AresRPG>(kiosk)) {
      kiosk_extension::enable<AresRPG>(kiosk, kiosk_owner_cap);
    };

    emit(CharacterCreateEvent {
      character_id
    });

    character_id
  }

  /// Move the character from the kiosk to the extension.
  public fun select_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &AresRPG_TransferPolicy<Character>,
    character_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let character = policy.extract_from_kiosk<Character>(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );

    place_character_in_extension(
      kiosk,
      character,
      ctx
    );

    emit(CharacterSelectEvent {
      character_id,
      kiosk_id: object::id(kiosk)
    });
  }

  /// Take the character from the extension and lock it back in the kiosk.
  public fun unselect_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &TransferPolicy<Character>,
    character_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let character = take_character_from_extension(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );

    assert!(character.borrow_inventory().is_empty(), EInventoryNotEmpty);

    kiosk.lock(kiosk_cap, policy, character);

    emit(CharacterUnselectEvent {
      character_id,
      kiosk_id: object::id(kiosk)
    });
  }

  /// We use the protected policy to freely access the character and delete it.
  /// A character must be unselected before being deleted.
  public fun delete_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    name_registry: &mut NameRegistry,
    character_id: ID,
    policy: &AresRPG_TransferPolicy<Character>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let character = policy.extract_from_kiosk<Character>(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );

    character.delete(name_registry);

    emit(CharacterDeleteEvent {
      character_id
    });
  }
}