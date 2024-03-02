module aresrpg::server {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::object::{Self, UID, ID};

  use std::string::{String};

  use aresrpg::discord_profile::{Self};
  use aresrpg::storage::{
    Self as ares_storage,
    StorageCap
  };

  struct AdminCap has key { id: UID }

  fun init(ctx: &mut TxContext) {
    transfer::transfer(
      AdminCap { id: object::new(ctx) },
      tx_context::sender(ctx)
    );
  }

  public fun request_storage(
    server_address: address,
    ctx: &mut TxContext
  ): (StorageCap, ID) {
    let (mutation_cap, storage_cap, storage_id) = ares_storage::create(ctx);

    transfer::public_transfer(mutation_cap, server_address);
    (storage_cap, storage_id)
  }

  public fun assign_discord_profile(
    _: &AdminCap,
    discord_id: String,
    to: address,
    ctx: &mut TxContext
  ) {
    let profile = discord_profile::create(discord_id, ctx);
    discord_profile::transfer(profile, to);
  }
}