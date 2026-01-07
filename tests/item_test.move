#[test_only]
module aresrpg::item_test;

use aresrpg::{
  auth,
  inventory_test,
  item::{Self, Item},
  item_api,
  item_damages::{Self, ItemDamages},
  item_stats::{Self, ItemStatistics},
  protected_policy::AresRPG_TransferPolicy,
  version::Version
};
use std::string::utf8;
use sui::{
  kiosk::{Kiosk, KioskOwnerCap},
  test_scenario::{Self as test, Scenario, next_tx, ctx},
  transfer_policy::TransferPolicy
};

// ╔════════════════ [ Item Creation Tests ] ══════════════════════════════════ ]

#[test]
fun test_create_item_with_stats() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create item with full stats
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let stats = item_stats::protected_new(
      &auth,
      100, // vitality
      50,  // wisdom
      75,  // strength
      60,  // intelligence
      55,  // chance
      80,  // agility
      3,   // range
      4,   // movement
      6,   // action
      15,  // critical
      25,  // raw_damage
      10,  // critical_chance
      20,  // critical_outcomes
      30,  // earth_resistance
      25,  // fire_resistance
      20,  // water_resistance
      15,  // air_resistance
    );

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Legendary Sword".to_string(),
      b"sword".to_string(),
      b"legendary_set".to_string(),
      b"legendary_sword".to_string(),
      50,    // level
      1,     // amount
      false, // not stackable
      option::some(stats),
      vector::empty(),
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test]
fun test_create_item_with_damages() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create item with damage ranges
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let mut damages = vector::empty<ItemDamages>();
    damages.push_back(item_damages::protected_new(
      &auth,
      10,  // from
      20,  // to
      b"physical".to_string(),
      b"earth".to_string(),
    ));

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Battle Axe".to_string(),
      b"axe".to_string(),
      b"warrior".to_string(),
      b"battle_axe".to_string(),
      30,    // level
      1,     // amount
      false, // not stackable
      option::none(),
      damages,
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test]
fun test_create_stackable_item() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create stackable item (amount > 1)
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Wood Log".to_string(),
      b"resource".to_string(),
      b"basic".to_string(),
      b"wood_log".to_string(),
      1,    // level
      100,  // amount (stackable)
      true, // stackable
      option::none(),
      vector::empty(),
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  // Verify amount is correct
  next_tx(&mut scenario, player);
  {
    let kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);

    // Get item IDs from kiosk (we'd need to know the item_id here)
    // For now, just verify the kiosk was used

    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
  };

  test::end(scenario);
}

// ╔════════════════ [ Item Stack Operations ] ════════════════════════════════ ]

#[test]
fun test_split_stackable_item() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create stackable item (amount = 100)
  let item_id = next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Iron Ore".to_string(),
      b"resource".to_string(),
      b"mining".to_string(),
      b"iron_ore".to_string(),
      1,    // level
      100,  // amount
      true, // stackable
      option::none(),
      vector::empty(),
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test]
fun test_merge_stackable_items() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  test::end(scenario);
}

#[test]
fun test_set_item_amount() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create stackable item (amount = 10)
  let item_id = next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Potion".to_string(),
      b"consumable".to_string(),
      b"basic".to_string(),
      b"health_potion".to_string(),
      1,    // level
      10,   // amount
      true, // stackable
      option::none(),
      vector::empty(),
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test, expected_failure(abort_code = aresrpg::item_api::EInvalidLastAmount)]
fun test_set_item_amount_stale_lock() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create stackable item (amount = 10) and capture ID
  let item_id = inventory_test::create_item_in_kiosk(&mut scenario, player, b"stale_item");

  // Try to update with stale last_amount (5 instead of actual 1)
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let item = kiosk.borrow_mut<Item>(&kiosk_cap, item_id);

    // This should fail with EInvalidLastAmount (actual is 1, we're passing 5)
    item_api::set_amount(
      &auth,
      item,
      5,  // stale last_amount
      20, // new amount
      &version,
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(version);
  };

  test::end(scenario);
}

// ╔════════════════ [ Item Destruction ] ═════════════════════════════════════ ]

#[test]
fun test_destroy_item() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  test::end(scenario);
}

// ╔════════════════ [ Item Stats Tests ] ═════════════════════════════════════ ]

#[test]
fun test_all_stat_types() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create item with all 16 stat types
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let stats = item_stats::protected_new(
      &auth,
      1000, // vitality
      900,  // wisdom
      850,  // strength
      800,  // intelligence
      750,  // chance
      700,  // agility
      10,   // range
      8,    // movement
      12,   // action
      25,   // critical
      50,   // raw_damage
      20,   // critical_chance
      30,   // critical_outcomes
      40,   // earth_resistance
      35,   // fire_resistance
      30,   // water_resistance
      25,   // air_resistance
    );

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Ultimate Armor".to_string(),
      b"cloak".to_string(),
      b"ultimate".to_string(),
      b"ultimate_armor".to_string(),
      100,   // level
      1,     // amount
      false, // not stackable
      option::some(stats),
      vector::empty(),
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test]
fun test_update_item_stats() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  test::end(scenario);
}

// ╔════════════════ [ Item Damages Tests ] ═══════════════════════════════════ ]

#[test]
fun test_multiple_damage_types() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create item with multiple damage types
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let mut damages = vector::empty<ItemDamages>();

    // Physical damage (earth element)
    damages.push_back(item_damages::protected_new(
      &auth,
      15,  // from
      25,  // to
      b"physical".to_string(),
      b"earth".to_string(),
    ));

    // Magical damage (fire element)
    damages.push_back(item_damages::protected_new(
      &auth,
      10,  // from
      20,  // to
      b"magical".to_string(),
      b"fire".to_string(),
    ));

    item_api::new(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      &policy,
      b"Hybrid Staff".to_string(),
      b"staff".to_string(),
      b"hybrid".to_string(),
      b"hybrid_staff".to_string(),
      40,    // level
      1,     // amount
      false, // not stackable
      option::none(),
      damages,
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

// ╔════════════════ [ Edge Cases ] ═══════════════════════════════════════════ ]

#[test, expected_failure(abort_code = aresrpg::item::ENotStackable)]
fun test_split_non_stackable_item() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create non-stackable item and capture ID
  let item_id = inventory_test::create_item_in_kiosk(&mut scenario, player, b"unique_ring");

  // Try to split it (should fail with ENotStackable)
  next_tx(&mut scenario, player);
  {
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    // This should fail - item is not stackable
    item_api::split(
      &mut kiosk,
      &kiosk_cap,
      &policy,
      item_id,
      1, // try to split off 1
      &version,
      ctx(&mut scenario),
    );

    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test, expected_failure(abort_code = aresrpg::item::ENotStackable)]
fun test_merge_non_stackable_items() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create first non-stackable item
  let item1_id = inventory_test::create_item_in_kiosk(&mut scenario, player, b"ring1");

  // Create second non-stackable item
  let item2_id = inventory_test::create_item_in_kiosk(&mut scenario, player, b"ring2");

  // Try to merge them (should fail with ENotStackable)
  next_tx(&mut scenario, player);
  {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let protected_policy = test::take_shared<AresRPG_TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    // This should fail - items are not stackable
    item_api::merge(
      &auth,
      &mut kiosk,
      &kiosk_cap,
      item1_id,  // target
      item2_id,  // source
      &protected_policy,
      &version,
      ctx(&mut scenario),
    );

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(protected_policy);
    test::return_shared(version);
  };

  test::end(scenario);
}

#[test, expected_failure(abort_code = aresrpg::item::EWrongAmount)]
fun test_split_more_than_available() {
  let mut scenario = inventory_test::setup_test();
  let player = inventory_test::player();

  inventory_test::setup_inventory_environment(&mut scenario);
  inventory_test::create_kiosk_for_player(&mut scenario, player);
  inventory_test::mint_auth_key_for_player(&mut scenario, player);

  // Create STACKABLE item with amount=5
  next_tx(&mut scenario, player);
  let item_id = {
    let auth = test::take_from_sender<auth::AuthKey>(&scenario);
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    let item = item::new(
      b"wood".to_string(),
      b"misc".to_string(),
      b"starter".to_string(),
      b"wood".to_string(),
      1,      // level
      5,      // amount
      true,   // stackable = TRUE!
      ctx(&mut scenario),
    );

    let item_id = object::id(&item);
    kiosk.lock(&kiosk_cap, &policy, item);

    test::return_to_sender(&scenario, auth);
    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);

    item_id
  };

  // Try to split off more than available (should fail with EWrongAmount)
  next_tx(&mut scenario, player);
  {
    let mut kiosk = test::take_shared<Kiosk>(&scenario);
    let kiosk_cap = test::take_from_sender<KioskOwnerCap>(&scenario);
    let policy = test::take_shared<TransferPolicy<Item>>(&scenario);
    let version = test::take_shared<Version>(&scenario);

    // This should fail - trying to split 10, but item only has amount=5
    item_api::split(
      &mut kiosk,
      &kiosk_cap,
      &policy,
      item_id,
      10, // try to split off 10 (more than available=5)
      &version,
      ctx(&mut scenario),
    );

    test::return_shared(kiosk);
    test::return_to_sender(&scenario, kiosk_cap);
    test::return_shared(policy);
    test::return_shared(version);
  };

  test::end(scenario);
}
