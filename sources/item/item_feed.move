module aresrpg::item_feed {

  // this module manages the ability to "feed" or augment an item under specific conditions
  // it allows to feed Sui to a suifren for example,
  // or runes on a sword to increase its power

  use std::{
    type_name,
    string::utf8
  };

  use sui::{
    balance::{Self, Balance},
    sui::SUI,
    coin::{Self, Coin},
    dynamic_object_field as dof,
  };

  use suifrens::suifrens::{SuiFren};
  use vaporeon::vaporeon::{Vaporeon};

  use aresrpg::{
    version::Version,
    events
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EAlreadyFed: u64 = 101;
  const EInvalidFeedAmount: u64 = 102;
  const EMaxFeed: u64 = 103;

  const HSUI: vector<u8> = b"02a56d35041b2974ec23aff7889d8f7390b53b08e8d8bb91aa55207a0d5dd723::hsui::HSUI";

  const SUIFREN_SUI_REQUIRED: u64 = 1;
  const VAPOREON_HSUI_REQUIRED: u64 = 5;

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct FeedableAbility<phantom T> has key, store {
    id: UID,
    stomach: Balance<T>,
    last_feed: u64,
  }

  public struct FeedKey has store, copy, drop {}

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  fun feed_pet<T>(
    uid: &mut UID,
    food: Coin<T>,
    feed_amount: u64,
    feed_max: u64,
    ctx: &mut TxContext,
  ) {
    events::emit_pet_feed_event(uid.to_inner());

    if(!dof::exists_(uid, FeedKey {})) {
      dof::add(uid, FeedKey {}, FeedableAbility<T> {
        id: object::new(ctx),
        stomach: balance::zero(),
        last_feed: 0,
      });
    };

    let feedable = dof::borrow_mut<FeedKey, FeedableAbility<T>>(uid, FeedKey {});

    // can only feed once per epoch
    assert!(ctx.epoch() > feedable.last_feed, EAlreadyFed);

    feedable.last_feed = ctx.epoch();

    // cost 1 sui to feed
    assert!(food.value<T>() == feed_amount, EInvalidFeedAmount);
    // the suifren can only eat 100 sui
    assert!(feedable.stomach.value() <= feed_max, EMaxFeed);

    coin::put(&mut feedable.stomach, food);
  }

  public fun feed_suifren<Fren>(
    pet: &mut SuiFren<Fren>,
    food: Coin<SUI>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    let uid_mut = pet.uid_mut();

    feed_pet(
      uid_mut,
      food,
      SUIFREN_SUI_REQUIRED * 1_000_000_000,
      SUIFREN_SUI_REQUIRED * 1_000_000_000 * 100,
      ctx,
    );
  }

  public fun feed_vaporeon<T>(
    pet: &mut Vaporeon,
    food: Coin<T>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    assert!(type_name::get<T>().into_string() == utf8(HSUI).to_ascii());

    let uid_mut = pet.uid();

    feed_pet(
      uid_mut,
      food,
      VAPOREON_HSUI_REQUIRED * 1_000_000_000,
      VAPOREON_HSUI_REQUIRED * 1_000_000_000 * 100,
      ctx,
    );
  }
}