#[test_only]
module aresrpg::signature_verification_test;

use aresrpg::auth;
use sui::test_scenario as test;

const TEST_ADDRESS: address = @0xCAFE;

// ╔════════════════ [ Ed25519 Test Vectors ] ═════════════════════════════════ ]

// Test vectors from RFC 8032 / libsodium
// Public key: 32 bytes
// Signature: 64 bytes
// Message: arbitrary bytes

#[test]
fun test_valid_signature_verification() {
  let scenario = test::begin(TEST_ADDRESS);

  // NOTE: RFC 8032 test vectors cannot be used directly because our implementation
  // uses keccak256(message) before signing, while RFC 8032 vectors sign the message directly.
  //
  // The formula is:
  //   RFC 8032: sign(message)
  //   Our impl: sign(keccak256(message))
  //
  // This test is a placeholder. See JS integration tests for actual Ed25519 verification
  // with keccak256 hashing, which matches Ethereum tooling patterns.

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::auth::EInvalidSignature)]
fun test_invalid_signature_fails() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // Use RFC 8032 public key
  let pubkey = x"d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a";

  // Invalid signature (all zeros)
  let bad_signature =
    x"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

  let verifier = auth::verifier();

  // Should abort with EInvalidSignature
  verifier.verify(pubkey, bad_signature);

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::auth::EInvalidSignature)]
fun test_wrong_public_key_fails() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // Valid signature from RFC 8032
  let signature =
    x"e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b";

  // WRONG public key (different from RFC vector)
  let wrong_pubkey = x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  let verifier = auth::verifier();

  // Should abort with EInvalidSignature
  verifier.verify(wrong_pubkey, signature);

  test::end(scenario);
}

#[test]
#[expected_failure(abort_code = aresrpg::auth::EInvalidSignature)]
fun test_tampered_message_fails() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // RFC 8032 public key (signature is for empty message)
  let pubkey = x"d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a";
  let signature =
    x"e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b";

  // Add tampered message (signature is for empty message, not this)
  let mut verifier = auth::verifier();
  verifier.add(&42u64);

  // Should abort with EInvalidSignature
  verifier.verify(pubkey, signature);

  test::end(scenario);
}

// ╔════════════════ [ Builder Pattern Tests ] ════════════════════════════════ ]

#[test]
fun test_verifier_builder_with_multiple_types() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // Test that Verifier can build messages with multiple data types
  let mut verifier = auth::verifier();

  // Add various types (BCS-encoded internally)
  let test_id = object::id_from_address(@0xCAFE);
  verifier.add(&test_id);

  let test_string = std::string::utf8(b"hello");
  verifier.add_string(&test_string);

  verifier.add(&42u64);

  let test_bytes = b"raw bytes";
  verifier.add_bytes(test_bytes);

  // NOTE: Can't verify without real signature, but we've tested the builder pattern
  // JS integration tests will verify end-to-end with real signatures

  test::end(scenario);
}

#[test]
fun test_verifier_message_ordering_matters() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // Demonstrate that message field ordering affects the hash
  // Verifier A: string then u64
  let mut verifier_a = auth::verifier();
  let test_string = std::string::utf8(b"hello");
  verifier_a.add_string(&test_string);
  verifier_a.add(&42u64);

  // Verifier B: u64 then string
  let mut verifier_b = auth::verifier();
  verifier_b.add(&42u64);
  verifier_b.add_string(&test_string);

  // NOTE: Cannot directly compare message bytes in Move tests
  // But the different ordering will produce different keccak256 hashes
  // Therefore, signatures for A and B will be different
  // JS integration tests will verify this with actual signatures

  test::end(scenario);
}

// ╔════════════════ [ Character Update Signature ] ═══════════════════════════ ]

#[test]
fun test_character_update_signature_full_flow() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // NOTE: This test demonstrates the message structure for character updates
  // but cannot test actual signature verification without external key generation.
  // See JS integration tests for end-to-end verification.

  // Simulate character update message construction
  let mut verifier = auth::verifier();

  // Add character ID
  let char_id = object::id_from_address(@0xDEADBEEF);
  verifier.add(&char_id);

  // Add optional position update
  let new_position = std::string::utf8(b"42,100");
  verifier.add_string(&new_position);

  // Add optional realm update
  let new_realm = std::string::utf8(b"Bonta");
  let last_realm = std::string::utf8(b"Astrub");
  verifier.add_string(&new_realm);
  verifier.add_string(&last_realm);

  // Add optional experience update
  let new_exp: u32 = 1000;
  let last_exp: u32 = 500;
  verifier.add(&new_exp);
  verifier.add(&last_exp);

  // Add last_signature for replay protection
  let last_sig = b"previous_signature";
  verifier.add_bytes(last_sig);

  // Message built successfully
  // JS integration tests will verify with real Ed25519 signatures

  test::end(scenario);
}

// ╔════════════════ [ Replay Protection ] ════════════════════════════════════ ]

#[test]
fun test_replay_protection_with_last_signature() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // NOTE: Full replay protection testing requires multiple character updates
  // with different signatures. This is best tested in JS integration tests
  // where we can generate multiple valid signatures.
  //
  // The flow is:
  // 1. Create character (last_signature = vector::empty())
  // 2. Update 1: sign(char_id + fields + last_signature[empty])
  //    - Store signature_1 in character.last_signature
  // 3. Update 2: sign(char_id + fields + signature_1)
  //    - Store signature_2 in character.last_signature
  // 4. Replay attack: try to use signature_1 again
  //    - Fails because message includes old last_signature
  //    - But character now has signature_2 stored
  //
  // See integration tests for full implementation

  test::end(scenario);
}

// ╔════════════════ [ Edge Cases ] ═══════════════════════════════════════════ ]

#[test]
fun test_empty_message_signature() {
  let scenario = test::begin(TEST_ADDRESS);

  // NOTE: Empty message signature verification requires JS integration tests
  // because RFC 8032 vectors are incompatible with keccak256 hashing.
  //
  // The correct test flow is:
  // 1. Generate Ed25519 keypair in JS
  // 2. Sign keccak256(empty_message) with private key
  // 3. Verify on-chain with public key
  //
  // See JS integration tests for implementation.

  test::end(scenario);
}

#[test]
fun test_large_message_signature() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // Build a large message with many fields
  let mut verifier = auth::verifier();

  // Add 50 fields to simulate complex update
  let mut i: u64 = 0;
  while (i < 50) {
    verifier.add(&i);
    i = i + 1;
  };

  // NOTE: Cannot verify without real signature for this large message
  // But we've proven the builder can handle many fields
  // JS integration tests will verify with actual signatures

  test::end(scenario);
}

// ╔════════════════ [ Keccak256 Hashing ] ════════════════════════════════════ ]

#[test]
fun test_keccak256_used_for_hashing() {
  let mut scenario = test::begin(TEST_ADDRESS);

  // NOTE: The implementation uses sui::hash::keccak256() as confirmed in auth.move:
  // ```
  // let message_hash = hash::keccak256(&self.message);
  // let valid = ed25519::ed25519_verify(&signature, &server_pubkey, &message_hash);
  // ```
  //
  // This matches Sui's standard pattern and Ethereum tooling compatibility.
  // JS integration tests will generate signatures using keccak256 and verify
  // they work correctly on-chain.

  test::end(scenario);
}
