#[test_only]
module aresrpg::character_test;

use aresrpg::{admin::AdminCap, auth, character::Character, derived::AresRoot, version::Version};
use std::string::utf8;
use sui::{
  kiosk::{Kiosk, KioskOwnerCap},
  test_scenario::{Self as test, Scenario, next_tx, ctx},
  transfer_policy::TransferPolicy
};

const ADMIN: address = @0xAD;
const PLAYER: address = @0xB0B;

// ╔════════════════ [ Setup Helpers ] ════════════════════════════════════════ ]

fun setup_test(): Scenario {
  let mut scenario = test::begin(ADMIN);

  // Initialize admin cap (in real init, this happens automatically)
  // For tests, we need to create it manually

  scenario
}

fun setup_character_environment(scenario: &mut Scenario) {}

// ╔════════════════ [ Character Creation Tests ] ═════════════════════════════ ]

#[test]
fun test_create_character_valid() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create character with valid parameters
  // - Name: "testchar" (valid: 3-20 chars, no whitespace)
  // - Class: "shugo" (valid class)
  // - Sex: male
  // - Colors: valid RGB values

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::ENameTaken)]
fun test_create_character_duplicate_name() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create two characters with same name
  // Should fail on second creation

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::ENameInvalid)]
fun test_create_character_name_too_short() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create character with name "ab" (< 3 chars)

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::ENameInvalid)]
fun test_create_character_name_with_whitespace() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create character with name "test char" (contains space)

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::EInvalidClasse)]
fun test_create_character_invalid_class() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create character with class "hacker" (invalid)

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::EInvalidColor)]
fun test_create_character_invalid_color() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO: Create character with color > 0xFFFFFF

  test::end(scenario);
}

// ╔════════════════ [ Character Update Tests ] ═══════════════════════════════ ]

#[test]
fun test_update_character_with_valid_signature() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character
  // 2. Generate Ed25519 signature for update
  // 3. Call update_character() with valid signature
  // 4. Verify fields updated correctly

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::auth::EInvalidSignature)]
fun test_update_character_invalid_signature() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character
  // 2. Generate signature with wrong message
  // 3. Call update_character() - should fail

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::EInvalidUpdate)]
fun test_update_character_stale_optimistic_lock() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character with experience = 100
  // 2. Try to update with last_experience = 50 (stale)
  // 3. Should fail optimistic lock check

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::EExperienceTooLow)]
fun test_update_character_experience_decrease() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character with experience = 100
  // 2. Try to update to experience = 50 (decrease)
  // 3. Should fail (experience can only increase)

  test::end(scenario);
}

#[test]
fun test_update_character_replay_protection() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character
  // 2. Update with signature A
  // 3. Try to replay same signature A
  // 4. Should fail (last_signature changed)

  test::end(scenario);
}

// ╔════════════════ [ Character Deletion Tests ] ═════════════════════════════ ]

#[test]
fun test_delete_character_empty_inventory() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character
  // 2. Delete character (inventory empty)
  // 3. Verify character object destroyed

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::character::EInventoryNotEmpty)]
fun test_delete_character_with_items() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // TODO:
  // 1. Create character
  // 2. Equip an item to character
  // 3. Try to delete - should fail

  test::end(scenario);
}

// ╔════════════════ [ All Classes Test ] ═════════════════════════════════════ ]

#[test]
fun test_all_character_classes() {
  let mut scenario = setup_test();
  setup_character_environment(&mut scenario);

  // Test all 12 valid classes:
  let classes = vector[
    utf8(b"shugo"),
    utf8(b"tomoda"),
    utf8(b"rojin"),
    utf8(b"yajin"),
    utf8(b"tokei"),
    utf8(b"asobi"),
    utf8(b"tsuba"),
    utf8(b"senshi"),
    utf8(b"yogan"),
    utf8(b"mori"),
    utf8(b"ikari"),
    utf8(b"shusen"),
  ];

  // TODO: Create character for each class
  // All should succeed

  test::end(scenario);
}
