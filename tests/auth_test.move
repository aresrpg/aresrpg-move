#[test_only]
module aresrpg::auth_test;

use aresrpg::auth;
use sui::test_scenario;

// Test constants
const TEST_ADDRESS: address = @0xA;

/// Test that verifier can be created and data can be added
#[test]
fun test_verifier_builder_pattern() {
  // Create a verifier
  let mut verifier = auth::verifier();

  // Add typed data (ID)
  let test_id = object::id_from_address(@0x123);
  verifier.add(&test_id);

  // Add string
  let test_string = b"hello world".to_string();
  verifier.add_string(&test_string);

  // Add raw bytes
  let test_bytes = b"raw bytes";
  verifier.add_bytes(test_bytes);

  // If we got here without panic, builder pattern works!
  // Actual signature verification will be tested via E2E on devnet
}
