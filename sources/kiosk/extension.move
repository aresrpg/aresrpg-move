module aresrpg::extension {

  // This module contains the AresRPG extension for the Kiosk.
  // It allows the AresRPG game master (admin) to borrow mutably characters
  // which are placed into the extension storage in order to update their stats.
  // The extension also allows the game master to place items in its storage.

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    kiosk_extension,
    object_bag::{Self, ObjectBag},
  };

  use aresrpg::{
    version::Version,
    character::Character,
    admin::AdminCap,
    promise::{await, Promise},
    item::Item
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

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

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

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Enables the admin to mutate a character stored in the extension.
  /// The promise ensure that the character is returned to the extension.
  public fun admin_borrow_character_val(
    admin: &AdminCap,
    kiosk: &mut Kiosk,
    character_id: ID,
    ctx: &mut TxContext
  ): (Character, Promise<ID>) {
    admin.verify(ctx);

    let obag = borrow_object_bag(kiosk, b"characters", ctx);
    let character = obag.remove(character_id);
    let promise = await(character_id);

    (character, promise)
  }

  public fun admin_return_character_val(
    admin: &AdminCap,
    kiosk: &mut Kiosk,
    character: Character,
    promise: Promise<ID>,
    ctx: &mut TxContext
  ) {
    admin.verify(ctx);
    assert!(promise.value() == object::id(&character), EWrongPromise);

    promise.resolve(object::id(&character));

    borrow_object_bag(kiosk, b"characters", ctx)
      .add(object::id(&character), character);
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════ ]

  // We need an object bag otherwise it will be impossible
  // to query a NFTs by their IDs.
  fun borrow_object_bag(
    kiosk: &mut Kiosk,
    key: vector<u8>,
    ctx: &mut TxContext
  ): &mut ObjectBag {
    let extension_bag = kiosk_extension::storage_mut(AresRPG {}, kiosk);

    if(!extension_bag.contains(key)) {
      extension_bag.add(key, object_bag::new(ctx));
    };

    extension_bag.borrow_mut(key)
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════ ]

  /// Enables the package to place a character within the AresRPG extension's characters object bag,
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

    borrow_object_bag(kiosk, b"characters", ctx)
      .add(object::id(&character), character);
  }

  public(package) fun take_character_from_extension(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    character_id: ID,
    ctx: &mut TxContext,
  ): Character {
      // only allow the owner of the kiosk to take from the bag
    assert!(kiosk.has_access(kiosk_cap), ENotOwner);

    let obag = borrow_object_bag(kiosk, b"characters", ctx);
    let mut character = obag.remove<ID, Character>(character_id);

    character.set_selected(false);
    character.remove_kiosk_id();

    character
  }

  public(package) fun place_item_in_extension(
    kiosk: &mut Kiosk,
    item: Item,
    ctx: &mut TxContext,
  ) {
    assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

    borrow_object_bag(kiosk, b"items", ctx)
      .add(object::id(&item), item);
  }

  public(package) fun take_item_from_extension(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    item_id: ID,
    ctx: &mut TxContext,
  ): Item {
    // only allow the owner of the kiosk to take from the bag
    assert!(kiosk.has_access(kiosk_cap), ENotOwner);

    let obag = borrow_object_bag(kiosk, b"items", ctx);
    obag.remove<ID, Item>(item_id)
  }

  public(package) fun borrow_character_mut(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    character_id: ID,
    ctx: &mut TxContext
  ): &mut Character {
    // only allow the owner of the kiosk to borrow a character
    assert!(kiosk.has_access(kiosk_cap), ENotOwner);

    let obag = borrow_object_bag(kiosk, b"characters", ctx);
    obag.borrow_mut(character_id)
  }

  public(package) fun borrow_item_mut(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    item_id: ID,
    ctx: &mut TxContext
  ): &mut Item {
    // only allow the owner of the kiosk to borrow an item
    assert!(kiosk.has_access(kiosk_cap), ENotOwner);

    let obag = borrow_object_bag(kiosk, b"items", ctx);
    obag.borrow_mut(item_id)
  }
}