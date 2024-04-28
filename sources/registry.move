module aresrpg::registry {

  use sui::{
    table::{Self, Table},
    tx_context::{sender}
  };

  use std::{
    string::{Self, String},
  };

  use aresrpg::{
    string::{contains_whitespace},
  };

  // ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

  const ENameInvalid: u64 = 2;
  const ENameTaken: u64 = 3;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct NameRegistry has key, store {
    id: UID,
    registry: Table<String, address>,
  }

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

  fun init(ctx: &mut TxContext) {
    let name_registry = NameRegistry {
      id: object::new(ctx),
      registry: table::new(ctx),
    };

    transfer::share_object(name_registry);
  }

  public(package) fun add_name(
    self: &mut NameRegistry,
    name: String,
    ctx: &TxContext
  ) {
    self.assert_name_available(name);
    assert_name_valid(name);

    table::add(&mut self.registry, name, sender(ctx));
  }

  public(package) fun remove_name(
    self: &mut NameRegistry,
    name: String,
  ) {
    table::remove(&mut self.registry, name);
  }

  // ╔════════════════ [ Read ] ════════════════════════════════════════════ ]

  public fun length(self: &NameRegistry): u64 {
    self.registry.length()
  }

  // ╔════════════════ [ Assertions ] ════════════════════════════════════════════ ]

  public fun assert_name_available(
    self: &NameRegistry,
    name: String
  ) {
    assert!(!self.registry.contains(name), ENameTaken);
  }

  public fun assert_name_valid(name: String) {
    assert!(string::length(&name) > 3 && string::length(&name) < 20, ENameInvalid);
    assert!(!contains_whitespace(name), ENameInvalid);
  }
}