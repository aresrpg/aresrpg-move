module aresrpg::auth;

use aresrpg::admin::AdminCap;

// This module provides authorization objects used for server-only functions

// ╔════════════════ [ Types ] ═══════════════════════════════════════════════ ]

public struct AuthKey has key, store {
  id: UID,
}

// ╔════════════════ [ Public ] ═══════════════════════════════════════════════ ]

public fun destroy(auth: AuthKey) {
  let AuthKey { id } = auth;
  object::delete(id);
}

// ╔════════════════ [ Admin ] ═══════════════════════════════════════════════ ]

/// The aresrpg gas-station will own a bunch of authKeys to sponsor players
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

// ╔════════════════ [ TEMPORARY ] ═══════════════════════════════════════════════ ]

/// While waiting for the official support of multi-agent transaction in Sui
/// https://github.com/sui-foundation/sips/pull/44
/// we will just authorize anyone to be an admin, for demonstration purposes
public fun unsecure_temporary_auth(ctx: &mut TxContext): AuthKey {
  AuthKey {
    id: object::new(ctx),
  }
}
