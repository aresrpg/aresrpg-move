#[test_only]
module aresrpg::inventory_test;

// NOTE: Inventory equip/unequip functions (character_inventory::equip_item, unequip_item)
// are NOT unit-testable via direct Move function calls due to Sui PTB limitations.
//
// REASON: These functions take `character: &mut Character` borrowed from a kiosk, and also
// require `&mut kiosk` to extract items. Move's borrow checker rejects having two mutable
// borrows of the same kiosk simultaneously in direct function calls.
//
// IN PRODUCTION: These functions work correctly via Programmable Transaction Blocks (PTBs)
// because the TypeScript SDK's kiosk_tx.borrow() uses the Kiosk Extension API with promise-
// based semantics, not direct Move borrows.
//
// TESTING STRATEGY: These functions are tested via integration tests (JavaScript/TypeScript)
// that construct actual PTBs, matching production usage. Direct Move unit tests cannot
// simulate PTB-specific APIs.
//
// REFERENCE: https://docs.sui.io/guides/developer/sui-101/simulating-refs
// - "PTBs do not currently allow the use of object references returned from transaction commands"
// - "Support for references in a PTB is planned" (future Sui enhancement)

use aresrpg::{
  auth,
  character::{Self, Character},
  character_inventory,
  derived::AresRoot,
  item::{Self, Item},
  protected_policy,
  version::Version
};
use std::string::utf8;
use sui::{
  kiosk::{Kiosk, KioskOwnerCap},
  object,
  package::Publisher,
  test_scenario::{Self as test, Scenario, next_tx, ctx},
  transfer_policy::{Self as transfer_policy, TransferPolicy}
};

const ADMIN: address = @0xAD;
const PLAYER: address = @0xB0B;

// ╔════════════════ [ Setup Helpers ] ════════════════════════════════════════ ]

/// Initialize test scenario
public fun setup_test(): Scenario {
  test::begin(ADMIN)
}

/// Setup complete environment for inventory tests
public fun setup_inventory_environment(scenario: &mut Scenario) {
  // Initialize AresRoot
  next_tx(scenario, ADMIN);
  {
    aresrpg::derived::test_init(ctx(scenario));
  };

  // Initialize Version
  next_tx(scenario, ADMIN);
  {
    aresrpg::version::test_init(ctx(scenario));
  };

  // Initialize Character (Publisher + Display)
  next_tx(scenario, ADMIN);
  {
    character::test_init(ctx(scenario));
  };

  // Initialize Item (Publisher + Display)
  next_tx(scenario, ADMIN);
  {
    item::test_init(ctx(scenario));
  };

  // Create regular TransferPolicy for Character
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);
    let (policy, policy_cap) = transfer_policy::new<Character>(&publisher, ctx(scenario));
    transfer::public_share_object(policy);
    transfer::public_transfer(policy_cap, ADMIN);
    test::return_to_sender(scenario, publisher);
  };

  // Create regular TransferPolicy for Item
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);
    let (policy, policy_cap) = transfer_policy::new<Item>(&publisher, ctx(scenario));
    transfer::public_share_object(policy);
    transfer::public_transfer(policy_cap, ADMIN);
    test::return_to_sender(scenario, publisher);
  };

  // Create and share AresRPG_TransferPolicy<Character>
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);
    let version = test::take_shared<Version>(scenario);
    protected_policy::mint_and_share_aresrpg_policy<Character>(
      &publisher,
      &version,
      ctx(scenario),
    );
    test::return_to_sender(scenario, publisher);
    test::return_shared(version);
  };

  // Create and share AresRPG_TransferPolicy<Item>
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);
    let version = test::take_shared<Version>(scenario);
    protected_policy::mint_and_share_aresrpg_policy<Item>(
      &publisher,
      &version,
      ctx(scenario),
    );
    test::return_to_sender(scenario, publisher);
    test::return_shared(version);
  };
}

/// Create a kiosk for the given player
public fun create_kiosk_for_player(scenario: &mut Scenario, player: address) {
  next_tx(scenario, player);
  {
    let (kiosk, kiosk_cap) = sui::kiosk::new(ctx(scenario));
    transfer::public_share_object(kiosk);
    transfer::public_transfer(kiosk_cap, player);
  };
}

/// Create a character for the given player and return its ID
public fun create_character_for_player(scenario: &mut Scenario, player: address, name: vector<u8>): ID {
  next_tx(scenario, player);
  {
    let mut root = test::take_shared<AresRoot>(scenario);
    let mut kiosk = test::take_shared<Kiosk>(scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(scenario);
    let policy = test::take_shared<TransferPolicy<Character>>(scenario);
    let version = test::take_shared<Version>(scenario);

    // Compute character ID using same logic as character::new
    let char_name = name.to_string().to_ascii().to_lowercase().to_string();
    let mut key_name = copy char_name;
    key_name.append(b"::character".to_string());
    let character_address = sui::derived_object::derive_address(object::id(&root), key_name);
    let character_id = object::id_from_address(character_address);

    character::new(
      &mut kiosk,
      &kiosk_cap,
      &mut root,
      &policy,
      name.to_string(),
      b"shugo".to_string(),
      true,
      0xFF0000,
      0x00FF00,
      0x0000FF,
      &version,
    );

    test::return_shared(root);
    test::return_shared(kiosk);
    test::return_to_sender(scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);

    character_id
  }
}

/// Create an item in the kiosk and return its ID
public fun create_item_in_kiosk(scenario: &mut Scenario, player: address, item_name: vector<u8>): ID {
  next_tx(scenario, player);
  {
    let mut kiosk = test::take_shared<Kiosk>(scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(scenario);

    // Use item::new() directly to get the item before locking
    let item = item::new(
      item_name.to_string(),
      b"misc".to_string(),
      b"starter".to_string(),
      b"iron".to_string(),
      1,      // level
      1,      // amount
      false,  // stackable
      ctx(scenario),
    );

    let item_id = object::id(&item);
    kiosk.lock(&kiosk_cap, &policy, item);

    test::return_shared(kiosk);
    test::return_to_sender(scenario, kiosk_cap);
    test::return_shared(policy);

    item_id
  }
}

/// Helper to mint and retrieve AuthKey for testing
public fun mint_auth_key_for_player(scenario: &mut Scenario, player: address) {
  next_tx(scenario, player);
  {
    auth::test_mint_auth_key(ctx(scenario));
  };
}

// Accessors
public fun player(): address { PLAYER }
public fun admin(): address { ADMIN }
