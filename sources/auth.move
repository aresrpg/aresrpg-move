module aresrpg::auth;

use aresrpg::admin::AdminCap;
use sui::{bcs, ed25519, hash};

// Public authentication port (hexagonal architecture)
// Adapters are embedded to avoid circular dependencies (Move limitation)

// ╔════════════════ [ Constants ] ═══════════════════════════════════════════ ]

const EInvalidSignature: u64 = 100;

// ╔════════════════ [ Types ] ═══════════════════════════════════════════════ ]

/// Verifier builds a message from transaction arguments and verifies server signature
public struct Verifier has drop {
  message: vector<u8>,
}

/// AuthKey capability for SIP-44 (future use)
/// Server will own these and pass them in multi-address transactions
public struct AuthKey has key, store {
  id: UID,
}

// ╔════════════════ [ Signed Payload Adapter - Ed25519 ] ════════════════════ ]

/// Create a new verifier instance
public fun verifier(): Verifier {
  Verifier { message: vector::empty() }
}

/// Add a typed value to the verification message (e.g., ID, address, u64)
public fun add<T>(self: &mut Verifier, value: &T) {
  let bytes = bcs::to_bytes(value);
  vector::append(&mut self.message, bytes);
}

/// Add a string to the verification message
public fun add_string(self: &mut Verifier, value: &std::string::String) {
  let bytes = bcs::to_bytes(value);
  vector::append(&mut self.message, bytes);
}

/// Add raw bytes to the verification message
public fun add_bytes(self: &mut Verifier, value: vector<u8>) {
  vector::append(&mut self.message, value);
}

/// Verify the signature against the constructed message
/// @param server_pubkey: Server's Ed25519 public key (32 bytes)
/// @param signature: Ed25519 signature (64 bytes)
public fun verify(self: &Verifier, server_pubkey: vector<u8>, signature: vector<u8>) {
  // Hash the message with keccak256 (Sui pattern)
  let message_hash = hash::keccak256(&self.message);

  // Verify Ed25519 signature
  let valid = ed25519::ed25519_verify(&signature, &server_pubkey, &message_hash);

  assert!(valid, EInvalidSignature);
}

// NOTE: Move 2024 automatically creates method syntax (Verifier.add(), Verifier.verify(), etc.)
// when first parameter is &self or &mut self from same module. No explicit 'use fun' needed.

// ╔════════════════ [ Future Adapters ] ═════════════════════════════════════ ]

// When SIP-58 is available, add:
// public fun verify_sponsor(expected_sponsor: address, ctx: &TxContext) { ... }

// When SIP-44 is available, add:
// public fun verify_multi_address(object_ids: vector<ID>, owners: vector<address>, ctx: &TxContext) { ... }

// ╔════════════════ [ Admin ] ═══════════════════════════════════════════════ ]

/// Destroy an AuthKey (for cleanup)
public fun destroy(auth: AuthKey) {
  let AuthKey { id } = auth;
  object::delete(id);
}

/// The aresrpg gas-station will own a bunch of authKeys to sponsor players (SIP-44 future)
public(package) fun mint_and_transfer(
  admin: &AdminCap,
  recipient: address,
  amount: u16,
  ctx: &mut TxContext,
) {
  admin.verify(ctx);

  let mut current: u16 = 0;

  while (current < amount) {
    let key = AuthKey {
      id: object::new(ctx),
    };

    transfer::transfer(key, recipient);

    current = current + 1;
  }
}
