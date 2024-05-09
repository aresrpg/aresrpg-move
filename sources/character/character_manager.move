module aresrpg::character_manager {

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::{TransferPolicy},
    kiosk_extension,
  };

  use std::string::{Self, String};

  use aresrpg::{
    character::{Self as a_character, Character},
    character_stats::{Self, CharacterStatistics},
    character_registry::{NameRegistry},
    extension::{
      Self,
      AresRPG,
      place_character_in_extension,
      take_character_from_extension,
    },
    protected_policy::AresRPG_TransferPolicy,
    version::Version,
    item::Item
  };

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct StatsKey has copy, drop, store {}

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

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
    character.add_field(StatsKey {}, character_stats::new());

    let character_id = object::id(&character);

    kiosk.lock<Character>(kiosk_owner_cap, policy, character);

    if(!kiosk_extension::is_installed<AresRPG>(kiosk)) {
      extension::install(kiosk, kiosk_owner_cap, version, ctx);
    };

    if(!kiosk_extension::is_enabled<AresRPG>(kiosk)) {
      kiosk_extension::enable<AresRPG>(kiosk, kiosk_owner_cap);
    };

    character_id
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
  }

  /// Take the character from the extension and put it back in the kiosk.
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

    kiosk.lock(kiosk_cap, policy, character);
  }

  /// We use the protected policy to freely access the character and delete it.
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

    character.delete(name_registry, ctx);
  }

  public fun reset_character_stats(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    character: &mut Character,
    orb_of_reset: &Item,
    policy: &AresRPG_TransferPolicy<Item>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();
    orb_of_reset.assert_item_type(string::utf8(b"reset_orb"));

    let item = policy.extract_from_kiosk<Item>(
      kiosk,
      cap,
      object::id(orb_of_reset),
      ctx
    );

    item.destroy();

    let stats = borrow_stats_mut(character);
    stats.reset();
  }

  public fun add_vitality_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_vitality(amount);
  }

  public fun add_wisdom_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_wisdom(amount);
  }

  public fun add_strength_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_strength(amount);
  }

  public fun add_intelligence_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_intelligence(amount);
  }

  public fun add_chance_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_chance(amount);
  }

  public fun add_agility_stats(
    character: &mut Character,
    amount: u16,
    version: &Version,
  ) {
    version.assert_latest();
    borrow_stats_mut(character).add_agility(amount);
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun borrow_stats_mut(character: &mut Character): &mut CharacterStatistics {
    character.borrow_field_mut<StatsKey, CharacterStatistics>(StatsKey {})
  }

}