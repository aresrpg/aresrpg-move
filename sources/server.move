module aresrpg::server {
  use sui::object::{Self, UID};
  use sui::object_bag::{Self, ObjectBag};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};

  use std::option;
  use std::string::String;

  use aresrpg::user::{User, DiscordProfile};

  // Attempted to lock a user that is already locked
  // This ensures there is a single user locked at a time per address
  const EUserAlreadyLocked: u64 = 0;
  const EUserNotLocked: u64 = 1;

  const EDiscordAccountAlreadyLinked: u64 = 2;

  /// Grants admin access to the publisher
  struct ServerAdminCap has key { id: UID }

  struct Server {
    users: ObjectBag<User>
  }

  fun init(ctx: &mut TxContext) {
    let adminCap = ServerAdminCap { id: object::new(ctx) };
    let sender = tx_context::sender(ctx);

    let server = Server {
      users: object_bag::new(ctx)
    };

    transfer::share_object(server);
    transfer::transfer(adminCap, sender);
  }

  entry fun create_user(): User {
    User { mastery: 0, discord_profile: option::none() };
  }

  /// Locks an user to let the server mutate it freely
  entry fun lock_user(server: &mut Server, user: User) {
    let sender = tx_context::sender(ctx);

    assert!(!object_bag::contains(&server.users, &sender), EUserAlreadyLocked);

    object_bag::add(&mut server.users, sender, user);
  }

  /// Unlock an user, disconnecting it from the server
  entry fun unlock_user(server: &mut Server) {
    let sender = tx_context::sender(ctx);

    assert!(object_bag::contains(&server.users, &sender), EUserNotLocked);

    object_bag::extract(&mut server.users, sender);
  }

  // === Server functions ===

  entry fun link_discord_profile(
    _: &ServerAdminCap,
    server: &mut Server,
    user_address: address,
    username: String,
    avatar: String
  ) {
    let user = object_bag::borrow_mut<address, User>(&server.users, user_address);

    assert!(option::is_none(&user.discord_profile), EDiscordAccountAlreadyLinked);

    option::fill(&mut user.discord_profile, DiscordProfile { username, avatar });
  }

}