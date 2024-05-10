module aresrpg::admin {

  use sui::tx_context::{sender};

  // ╔════════════════ [ Types ] ═══════════════════════════════════════════════ ]

  // Allows admin actions like mutating player data
  public struct AdminCap has key, store { id: UID }

  fun init(ctx: &mut TxContext) {
    let cap = AdminCap {
      id: object::new(ctx),
    };

    transfer::transfer(cap, sender(ctx));
  }

}