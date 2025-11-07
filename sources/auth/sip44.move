module aresrpg::sip44;

// SIP-44: Multi-Address Object Usage
// https://github.com/sui-foundation/sips/pull/44
//
// FUTURE: When SIP-44 is available, transactions can use objects from multiple addresses
// This allows server to pass items while user passes character in atomic transaction

// ╔════════════════ [ Constants ] ═══════════════════════════════════════════ ]

const ENotImplemented: u64 = 300;
const EInvalidObjectOwnership: u64 = 301;

// ╔════════════════ [ Public(package) ] ═════════════════════════════════════ ]

/// Verify objects are owned by expected addresses (SIP-44)
/// STUB: Throws until SIP-44 is implemented in Sui
public(package) fun verify_multi_address(
  _object_ids: vector<ID>,
  _expected_owners: vector<address>,
  _ctx: &TxContext,
) {
  abort ENotImplemented
}

// ╔════════════════ [ Future Implementation ] ═══════════════════════════════ ]

// When SIP-44 is available:
//
// public(package) fun verify_multi_address(
//   object_ids: vector<ID>,
//   expected_owners: vector<address>,
//   ctx: &TxContext,
// ) {
//   assert!(vector::length(&object_ids) == vector::length(&expected_owners), EInvalidObjectOwnership);
//
//   let mut i = 0;
//   while (i < vector::length(&object_ids)) {
//     let object_id = vector::borrow(&object_ids, i);
//     let expected_owner = vector::borrow(&expected_owners, i);
//
//     // SIP-44: Verify object ownership via tx_context
//     let actual_owner = tx_context::object_owner(ctx, *object_id);
//     assert!(actual_owner == *expected_owner, EInvalidObjectOwnership);
//
//     i = i + 1;
//   };
// }
