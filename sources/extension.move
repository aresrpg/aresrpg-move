module aresrpg::extension {

  /// This module contains the AresRPG extension for the Kiosk.
  /// It allows the AresRPG game master (admin) to borrow mutably characters
  /// which are placed into the extension storage in order to update their stats.

  use sui::{
    kiosk::{Kiosk, KioskOwnerCap},
    kiosk_extension,
    transfer_policy::{Self, TransferPolicy, TransferPolicyCap},
    package::Publisher,
    bag,
    coin::{Self},
    sui::SUI,
  };

  use aresrpg::version::Version;

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const KIOSK_EXTENSION_PERMISSIONS: u128 = 11;

  const EObjectNotExist: u64 = 1;
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

  /// Enables someone to place an asset within the AresRPG extension's Bag,
  /// creating a Bag entry with the asset's ID as the key and the NFT as the value.
  /// Requires the existance of am AresRPG_TransferPolicy which can only be created by the creator of type T.
  /// Assumes item is already placed (& optionally locked) in a Kiosk.
  public(package) fun place_in_extension<T: key + store>(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    policy: &AresRPG_TransferPolicy<T>,
    item_id: ID,
    ctx: &mut TxContext,
  ) {
      assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

      kiosk.set_owner(cap, ctx);
      kiosk.list<T>(cap, item_id, 0);

      let coin = coin::zero<SUI>(ctx);
      let (object, request) = kiosk.purchase<T>(item_id, coin);

      let (_item, _paid, _from) = policy.transfer_policy.confirm_request(request);

      place_in_bag<T, ID>(kiosk, item_id, object);
  }

  /// Allow the admin to lock the object back to the owner's Kiosk.
  public(package) fun take_from_extension<T: key + store>(
      kiosk: &mut Kiosk,
      cap: &KioskOwnerCap,
      item_id: ID,
      _ctx: &mut TxContext,
  ): T {
      assert!(kiosk.has_access(cap), ENotOwner);

      take_from_bag<T, ID>(kiosk, item_id)
  }

  fun take_from_bag<T: key + store, Key: store + copy + drop>(
      kiosk: &mut Kiosk,
      key: Key,
  ) : T {
      let ext_storage_mut = kiosk_extension::storage_mut(AresRPG {}, kiosk);
      assert!(bag::contains(ext_storage_mut, key), EObjectNotExist);
      bag::remove<Key, T>(ext_storage_mut, key)
  }

  fun place_in_bag<T: key + store, Key: store + copy + drop>(
      kiosk: &mut Kiosk,
      key: Key,
      item: T,
  ) {
      let ext_storage_mut = kiosk_extension::storage_mut(AresRPG {}, kiosk);
      bag::add(ext_storage_mut, key, item);
  }
}