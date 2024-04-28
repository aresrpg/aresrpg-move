module aresrpg::aresrpg {

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::{TransferPolicy},
  };

  use std::string::{String};

  use aresrpg::{
    character::{Self as a_character, Character},
    registry::{NameRegistry},
    extension::{
      AresRPG_TransferPolicy,
      place_in_extension,
      take_from_extension
    },
    version::Version
  };

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

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
  ) {
    version.assert_latest();

    let character = a_character::create(
      name_registry,
      raw_name,
      classe,
      sex,
      ctx,
    );

    kiosk.lock<Character>(kiosk_owner_cap, policy, character);
  }

  public fun select_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &AresRPG_TransferPolicy<Character>,
    character_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    place_in_extension(kiosk, kiosk_cap, policy, character_id, ctx);
  }

  /// Take the character from the extension and put it back in the kiosk.
  ///! We lock it because Characters must be locked by design, no need for genericity.
  public fun unselect_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    policy: &TransferPolicy<Character>,
    character_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let character = take_from_extension(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );

    kiosk.lock(kiosk_cap, policy, character);
  }

  /// A character inside the extension bag can be deleted
  /// because the extension has free access to characters.
  /// We enforce the presence of a valid KioskOwnerCap to ensure that
  /// the caller owns the kiosk.
  public fun delete_character(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    name_registry: &mut NameRegistry,
    character_id: ID,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let character = take_from_extension<Character>(
      kiosk,
      kiosk_cap,
      character_id,
      ctx
    );

    character.delete(name_registry, ctx);
  }
}