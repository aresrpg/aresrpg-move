module aresrpg::extension {

  /// This module contains the AresRPG extension for the Kiosk.
  /// It allows the AresRPG game master (admin) to borrow mutably characters
  /// which are placed into the extension storage in order to update their stats.

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    kiosk_extension,
    transfer_policy::{Self, TransferPolicy, TransferPolicyCap},
    package::Publisher,
    object_bag::{Self, ObjectBag},
    coin::{Self},
    sui::SUI,
  };

  use aresrpg::{
    version::Version,
    character::Character,
    admin::AdminCap,
    promise::{await, Promise}
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  /// AresRPG can place and lock items in the Kiosk
  const KIOSK_EXTENSION_PERMISSIONS: u128 = 11;

  const EWrongPromise : u64 = 1;
  const EExtensionNotInstalled: u64 = 2;
  const ENotOwner: u64 = 3;

  // ╔════════════════ [ Types ] ══════════════════════════════════════════════ ]

  /// Extension Key for Kiosk AresRpg extension.
  public struct AresRPG has drop {}

  /// This policy grants AresRPG the right to bypass a Kiosk's lock and rules.
  /// It should be minted by any creators wanting to allow
  /// their NFTs to be directly equipped on AresRPG's characters.
  /// The action itself is safe but it will allow anyone to sell a character
  /// with the NFT on it, hence bypassing any other transfer policy made by the creator.
  public struct AresRPG_TransferPolicy<phantom T> has key, store {
    id: UID,
    transfer_policy: TransferPolicy<T>,
    policy_cap: TransferPolicyCap<T>
  }

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

  /// Enables someone to install the AresRPG extension in their Kiosk.
  public fun install(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    kiosk_extension::add(
      AresRPG {},
      kiosk,
      cap,
      KIOSK_EXTENSION_PERMISSIONS,
      ctx
    );
  }

  /// Remove the extension from the Kiosk. Can only be performed by the owner,
  /// The extension storage must be empty for the transaction to succeed.
  public fun remove(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    version: &Version
  ) {
    version.assert_latest();
    kiosk_extension::remove<AresRPG>(kiosk, cap);
  }

  /// Mint an AresRPG_TransferPolicy allowing AresRPG to freely move a NFT inside a Kiosk.
  /// Can only be performed by the publisher of type T.
  /// !! Make sure to understand the implications of this policy before using it !!
  public fun mint_and_share_aresrpg_policy<T>(
    publisher: &Publisher,
    version: &Version,
    ctx: &mut TxContext
  ) {
    version.assert_latest();

    // Creates an empty TP and shares an aresrpg_policy<T> object.
    // This can be used to bypass the lock rule under specific conditions.
    // Storing the cap inside the AresRPG_TransferPolicy with no way to access it
    // as we do not want to modify this policy
    let (transfer_policy, policy_cap) = transfer_policy::new<T>(publisher, ctx);

    let aresrpg_policy = AresRPG_TransferPolicy {
      id: object::new(ctx),
      transfer_policy,
      policy_cap,
    };

    transfer::share_object(aresrpg_policy);
  }

  /// Enables someone to place a character within the AresRPG extension's characters object bag,
  /// which is contained in the extension storage of the Kiosk.
  /// Requires the existance of an AresRPG_TransferPolicy which can only be created by the creator of type Character.
  /// Assumes character is already locked in a Kiosk.
  public(package) fun place_character_in_extension(
    kiosk: &mut Kiosk,
    character: Character,
    ctx: &mut TxContext,
  ) {
      assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

      let mut character = character;

      character.set_selected(true);
      character.set_kiosk_id(object::id(kiosk));

      place_in_characters_bag(kiosk, character.inner_id(), character, ctx);
  }

  public(package) fun take_character_from_extension(
      kiosk: &mut Kiosk,
      kiosk_cap: &KioskOwnerCap,
      character_id: ID,
      ctx: &mut TxContext,
  ): Character {
      // only allow the owner of the kiosk to take from the bag
      assert!(kiosk.has_access(kiosk_cap), ENotOwner);

      let mut character = take_from_characters_bag(kiosk, character_id, ctx);

      character.set_selected(false);
      character.remove_kiosk_id();

      character
  }

  public(package) fun take_character_from_kiosk(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    policy: &AresRPG_TransferPolicy<Character>,
    character_id: ID,
    ctx: &mut TxContext,
  ): Character {
      assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

      kiosk.set_owner(cap, ctx);
      // we list the item to transfer it
      kiosk.list<Character>(cap, character_id, 0);

      let coin = coin::zero<SUI>(ctx);
      let (object, request) = kiosk.purchase<Character>(character_id, coin);

      let (_item, _paid, _from) = policy.transfer_policy.confirm_request(request);

      object
  }

  public fun borrow_character_val(
    _admin: &AdminCap,
    kiosk: &mut Kiosk,
    character_id: ID,
    ctx: &mut TxContext
  ): (Character, Promise<ID>) {
    let character = take_from_characters_bag(kiosk, character_id, ctx);
    let promise = await(character_id);

    (character, promise)
  }

  public fun return_character_val(
    _admin: &AdminCap,
    kiosk: &mut Kiosk,
    character: Character,
    promise: Promise<ID>,
    ctx: &mut TxContext
  ) {
    assert!(promise.value() == character.inner_id(), EWrongPromise);

    promise.resolve();
    place_in_characters_bag(kiosk, character.inner_id(), character, ctx);
  }

  fun take_from_characters_bag(
    kiosk: &mut Kiosk,
    character_id: ID,
    ctx: &mut TxContext
  ): Character {
    borrow_characters_bag(kiosk, ctx).remove(character_id)
  }

  fun place_in_characters_bag(
    kiosk: &mut Kiosk,
    character_id: ID,
    character: Character,
    ctx: &mut TxContext
  ) {
    borrow_characters_bag(kiosk, ctx).add(character_id, character);
  }

  // We need an object bag otherwise it will be impossible
  // to query a character by its ID.
  fun borrow_characters_bag(
    kiosk: &mut Kiosk,
    ctx: &mut TxContext
  ): &mut ObjectBag {
    let extension_bag = kiosk_extension::storage_mut(AresRPG {}, kiosk);

    if(!extension_bag.contains(b"characters")) {
      extension_bag.add(b"characters", object_bag::new(ctx));
    };

    extension_bag.borrow_mut(b"characters")
  }
}