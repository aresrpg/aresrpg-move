module aresrpg::server {
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::object::{Self, UID};

  use std::string::{String};

  use aresrpg::discord_profile::{Self};

  struct AdminCap has key { id: UID }

  fun init(ctx: &mut TxContext) {
    transfer::transfer(
      AdminCap { id: object::new(ctx) },
      tx_context::sender(ctx)
    );
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