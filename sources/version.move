module aresrpg::version {

  use aresrpg::admin::AdminCap;

  // The version is used to make sure important functions
  // are not called on an outdated version of the package.
  const PACKAGE_VERSION: u64 = 2;

  // ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

  const EVersionMismatch: u64 = 1;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Version has key, store {
    id: UID,
    current_version: u64
  }

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

  fun init(ctx: &mut TxContext) {
    let version = Version {
      id: object::new(ctx),
      current_version: PACKAGE_VERSION,
    };

    transfer::share_object(version);
  }

  /// Migrate the package to the latest version,
  /// this prevent usage of old functions when the Version object is required
  entry fun update(self: &mut Version, _: &AdminCap) {
    assert!(self.current_version < PACKAGE_VERSION, EVersionMismatch);
    self.current_version = PACKAGE_VERSION;
  }

  // ╔════════════════ [ Assertions ] ════════════════════════════════════════════ ]

  /// Ensure the version is the latest
  public fun assert_latest(self: &Version) {
    assert!(self.current_version == PACKAGE_VERSION, EVersionMismatch);
  }

}