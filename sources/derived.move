module aresrpg::derived;

// This module initializes the root object for future derivation.

// ╔════════════════ [ Types ] ═══════════════════════════════════════════════ ]

public struct AresRoot has key, store {
  id: UID,
}

fun init(ctx: &mut TxContext) {
  let root = AresRoot {
    id: object::new(ctx),
  };

  transfer::share_object(root);
}

// ╔════════════════ [ Package ] ═══════════════════════════════════════════════ ]

public(package) fun uid(root: &mut AresRoot): &mut UID {
  &mut root.id
}

// ╔════════════════ [ Testing ] ═══════════════════════════════════════════════ ]

#[test_only]
/// Wrapper of module initializer for testing
public fun test_init(ctx: &mut TxContext) {
  init(ctx);
}
