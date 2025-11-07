module aresrpg::sip58;

// SIP-58: Transaction Context Signers
// https://github.com/sui-foundation/sips/pull/58
//
// FUTURE: When SIP-58 is available, tx_context will expose sponsor address
// This allows verifying the server sponsored the transaction

// ╔════════════════ [ Constants ] ═══════════════════════════════════════════ ]

const ENotImplemented: u64 = 200;
const EInvalidSponsor: u64 = 201;

// ╔════════════════ [ Public(package) ] ═════════════════════════════════════ ]

/// Verify transaction was sponsored by expected address (SIP-58)
/// STUB: Throws until SIP-58 is implemented in Sui
public(package) fun verify_sponsor(_expected_sponsor: address, _ctx: &TxContext) {
  abort ENotImplemented
}

// ╔════════════════ [ Future Implementation ] ═══════════════════════════════ ]

// When SIP-58 is available:
//
// public(package) fun verify_sponsor(
//   expected_sponsor: address,
//   ctx: &TxContext,
// ) {
//   let actual_sponsor = tx_context::sponsor(ctx);  // SIP-58 function
//   assert!(actual_sponsor == expected_sponsor, EInvalidSponsor);
// }
