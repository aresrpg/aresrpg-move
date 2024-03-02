module aresrpg::discord_profile {
  use sui::object::{Self, UID};
  use sui::tx_context::{TxContext};
  use sui::transfer;

  use std::string::{String};

  friend aresrpg::server;

    /// An object issued to an address after signed verification of ownership
  struct DiscordProfile has key {
    id: UID,
    discord_id: String,
  }

  public(friend) fun create(
    discord_id: String,
    ctx: &mut TxContext
  ): DiscordProfile {
    DiscordProfile {
      id: object::new(ctx),
      discord_id,
    }
  }

  public(friend) fun transfer(
    profile: DiscordProfile,
    to: address,
  ) {
    transfer::transfer(profile, to);
  }
}