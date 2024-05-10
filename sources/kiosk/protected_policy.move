module aresrpg::protected_policy {

  use sui::{
    transfer_policy::{Self, TransferPolicy, TransferPolicyCap},
    package::Publisher,
    kiosk::{Kiosk, KioskOwnerCap},
    coin::{Self},
    sui::SUI,
  };

  use aresrpg::{
    version::Version,
  };

  // ╔════════════════ [ Types ] ══════════════════════════════════════════════ ]

  /// This policy grants AresRPG the right to bypass a Kiosk's lock and rules.
  /// Its purpose is to allow characters and items to be freely used by the game.
  public struct AresRPG_TransferPolicy<phantom T> has key, store {
    id: UID,
    transfer_policy: TransferPolicy<T>,
    policy_cap: TransferPolicyCap<T>
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Mint an AresRPG_TransferPolicy allowing AresRPG to freely dispose of a NFT type after purschasing it.
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

    transfer::share_object(AresRPG_TransferPolicy {
      id: object::new(ctx),
      transfer_policy,
      policy_cap,
    });
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════ ]

  /// Allows the package to use the AresRPG protected policy for <T>
  /// to freely use any NFTs from a Kiosk.
  public(package) fun extract_from_kiosk<T: key + store>(
    self: &AresRPG_TransferPolicy<T>,
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    item_id: ID,
    ctx: &mut TxContext,
  ): T {
    kiosk.set_owner(cap, ctx);
    // we list the item to transfer it
    kiosk.list<T>(cap, item_id, 0);

    let coin = coin::zero<SUI>(ctx);
    let (object, request) = kiosk.purchase<T>(item_id, coin);

    let (_item, _paid, _from) = self.transfer_policy.confirm_request(request);

    object
  }
}