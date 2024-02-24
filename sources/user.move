module aresrpg::user {
  use std::string::String;
  use std::option::{Self, Option};

  struct User has key, store {
    mastery: u16
    discord_profile: Option<DiscordProfile>
  }

  struct DiscordProfile has key, store {
    username: String
    avatar: String
  }

}