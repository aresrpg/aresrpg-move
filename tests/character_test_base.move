#[test_only]
module aresrpg::character_test;

use aresrpg::{
  auth,
  character,
  derived::AresRoot,
  protected_policy,
  version::Version
};
use std::string::utf8;
use sui::{
  derived_object,
  kiosk::{Kiosk, KioskOwnerCap},
  object,
  package::Publisher,
  test_scenario::{Self as test, Scenario, next_tx, ctx},
  transfer_policy::{Self as transfer_policy, TransferPolicy}
};

// ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

const ADMIN: address = @0xAD;
const PLAYER: address = @0x1;

const MIN_COLOR_VALUE: u32 = 0;
const MAX_COLOR_VALUE: u32 = 16777215; // 0xFFFFFF

// ╔════════════════ [ Shared Helpers ] ═══════════════════════════════════════ ]

/// Initialize test scenario
public fun setup_test(): Scenario {
  test::begin(ADMIN)
}

/// Setup the environment by calling all module initializers
public fun setup_character_environment(scenario: &mut Scenario) {
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

  // Create regular TransferPolicy for Character
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);

    let (policy, policy_cap) = transfer_policy::new<character::Character>(&publisher, ctx(scenario));
    transfer::public_share_object(policy);
    transfer::public_transfer(policy_cap, ADMIN);

    test::return_to_sender(scenario, publisher);
  };

  // Create and share AresRPG_TransferPolicy<Character> (for deletion)
  next_tx(scenario, ADMIN);
  {
    let publisher = test::take_from_sender<Publisher>(scenario);
    let version = test::take_shared<Version>(scenario);

    protected_policy::mint_and_share_aresrpg_policy<character::Character>(
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

// ╔════════════════ [ Constants Accessors ] ══════════════════════════════════ ]

public fun admin(): address { ADMIN }
public fun player(): address { PLAYER }
public fun max_color_value(): u32 { MAX_COLOR_VALUE }
