module aresrpg::item_feed;

use aresrpg::{auth::AuthKey, events, version::Version};
use sui::{balance::{Self, Balance}, coin::{Self, Coin}, dynamic_object_field as dof};

// this module manages the ability to "feed" or augment an item under specific conditions
// it allows to feed Sui to a suifren for example,
// or runes on a sword to increase its power

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

const EAlreadyFed: u64 = 101;
const EInvalidFeedAmount: u64 = 102;
const EMaxFeed: u64 = 103;

// ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

public struct FeedableAbility<phantom T> has key, store {
  id: UID,
  stomach: Balance<T>,
  last_feed: u64,
  pet_id: ID,
}

public struct FeedKey has store, copy, drop {}

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

public fun feed_pet<T>(
  _auth: &AuthKey,
  uid: &mut UID,
  food: Coin<T>,
  feed_amount: u64,
  feed_max: u64,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let pet_id = uid.to_inner();
  events::emit_pet_feed_event(pet_id);

  if (!dof::exists_(uid, FeedKey {})) {
    dof::add(
      uid,
      FeedKey {},
      FeedableAbility<T> {
        id: object::new(ctx),
        stomach: balance::zero(),
        last_feed: 0,
        pet_id,
      },
    );
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
