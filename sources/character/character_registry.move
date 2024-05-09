module aresrpg::character_registry {

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
    registry: Table<String, ID>,
  }


  fun init(ctx: &mut TxContext) {
    let name_registry = NameRegistry {
      id: object::new(ctx),
      registry: table::new(ctx),
    };

    transfer::share_object(name_registry);
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun add_name(
    self: &mut NameRegistry,
    name: String,
    ctx: &TxContext
  ) {
    self.assert_name_available(name);
    assert_name_valid(name);

    self.registry.add(name, object::id_from_address(sender(ctx)));
  }

  public(package) fun remove_name(
    self: &mut NameRegistry,
    name: String,
  ) {
    table::remove(&mut self.registry, name);
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun length(self: &NameRegistry): u64 {
    self.registry.length()
  }

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