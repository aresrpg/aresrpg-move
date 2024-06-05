module aresrpg::item_feed {

  // this module manages the ability to "feed" or augment an item under specific conditions
  // it allows to feed Sui to a suifren for example,
  // or runes on a sword to increase its power

  use sui::{
    balance::{Self, Balance},
    sui::SUI,
    coin::{Self, Coin},
    dynamic_object_field as dof,
  };

  use suifrens::suifrens::{SuiFren};

  use aresrpg::{
    version::Version,
    events
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EAlreadyFed: u64 = 101;
  const EInvalidFeedAmount: u64 = 102;
  const EMaxFeed: u64 = 103;

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct FeedableAbility has key, store {
    id: UID,
    stomach: Balance<SUI>,
    last_feed: u64,
  }

  public struct FeedKey has store, copy, drop {}

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun feed_suifren<Fren>(
    suifren: &mut SuiFren<Fren>,
    food: Coin<SUI>,
    version: &Version,
    ctx: &mut TxContext,
  ) {
    version.assert_latest();

    events::emit_pet_feed_event(object::id(suifren));

    let uid_mut = suifren.uid_mut();

    if(!dof::exists_(uid_mut, FeedKey {})) {
      dof::add(uid_mut, FeedKey {}, FeedableAbility {
        id: object::new(ctx),
        stomach: balance::zero(),
        last_feed: 0,
      });
    };

    let feedable = dof::borrow_mut<FeedKey, FeedableAbility>(uid_mut, FeedKey {});

    // can only feed once per epoch
    assert!(ctx.epoch() > feedable.last_feed, EAlreadyFed);

    feedable.last_feed = ctx.epoch();

    // cost 1 sui to feed
    assert!(food.value<SUI>() == 1_000_000_000, EInvalidFeedAmount);
    // the suifren can only eat 100 sui
    assert!(feedable.stomach.value() <= 1_000_000_000 * 100, EMaxFeed);

    coin::put(&mut feedable.stomach, food);
  }
}