module aresrpg::admin {

  use sui::tx_context::{sender};

  // ╔════════════════ [ Constants ] ═══════════════════════════════════════════════ ]

  const EAdminCapExpired: u64 = 1;
  const ENotSuperAdmin: u64 = 2;

  // ╔════════════════ [ Types ] ═══════════════════════════════════════════════ ]

  // Allows admin actions like mutating player data
  public struct AdminCap has key, store {
    id: UID,
    epoch: u64
  }

  fun init(ctx: &mut TxContext) {
    let cap = AdminCap {
      id: object::new(ctx),
      // super admin
      epoch: 0,
    };

    transfer::transfer(cap, sender(ctx));
  }

  // ╔════════════════ [ Admin ] ═══════════════════════════════════════════════ ]

  entry fun admin_promote_address(
    admin: &AdminCap,
    recipient: address,
    ctx: &mut TxContext,
  ) {
    assert!(admin.super_admin(), ENotSuperAdmin);

    let cap = AdminCap {
      id: object::new(ctx),
      epoch: ctx.epoch(),
    };

    transfer::transfer(cap, recipient);
  }

  // ╔════════════════ [ Package ] ═══════════════════════════════════════════════ ]

  public(package) fun verify(
    self: &AdminCap,
    ctx: &TxContext,
  ) {
    if(!self.super_admin()) {
      assert!(self.epoch == ctx.epoch(), EAdminCapExpired);
    }
  }

  // ╔════════════════ [ Private ] ═══════════════════════════════════════════════ ]

  fun super_admin(self: &AdminCap): bool {
    self.epoch == 0
  }
}