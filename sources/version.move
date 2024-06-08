module aresrpg::version {

  // This module is used to keep track of the current version of the package
  // and to ensure that the package is not used with an outdated version.

  use aresrpg::admin::AdminCap;

  // The version is used to make sure important functions
  // are not called on an outdated version of the package.
  const PACKAGE_VERSION: u64 = 1;

  // ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

  const EVersionMismatch: u64 = 1;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Version has key, store {
    id: UID,
    current_version: u64
  }

  fun init(ctx: &mut TxContext) {
    let version = Version {
      id: object::new(ctx),
      current_version: PACKAGE_VERSION,
    };

    transfer::share_object(version);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Migrate the package to the latest version,
  /// this prevent usage of old functions when the Version object is required
  entry fun admin_update(
    self: &mut Version,
    admin: &AdminCap,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    assert!(self.current_version < PACKAGE_VERSION, EVersionMismatch);
    self.current_version = PACKAGE_VERSION;
  }

  /// Freeze the package to temporarily disable all public facing functions
  entry fun admin_freeze(
    self: &mut Version,
    admin: &AdminCap,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    self.current_version = 0;
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Ensure the version is the latest
  public fun assert_latest(self: &Version) {
    assert!(self.current_version == PACKAGE_VERSION, EVersionMismatch);
  }
}