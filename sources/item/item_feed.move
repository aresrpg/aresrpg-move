module aresrpg::item_feed;

use aresrpg::{auth::AuthKey, events, item::Item, version::Version};
use sui::{balance::{Self, Balance}, coin::{Self, Coin}, dynamic_object_field as dof, sui::SUI};
use suifrens::suifrens::SuiFren;
use vaporeon::vaporeon::Vaporeon;

// this module manages the ability to "feed" or augment an item under specific conditions
// it allows to feed Sui to a suifren for example,
// or runes on a sword to increase its power

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

const EAlreadyFed: u64 = 101;
const ENotPet: u64 = 102;
const EMaxFeed: u64 = 103;

// ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

public struct FeedableAbility<phantom T> has key, store {
  id: UID,
  stomach: Balance<T>,
  feed_percent: u8,
  last_feed: u64,
  pet_id: ID,
}

public struct FeedKey has store, copy, drop {}

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

/// Feed a pet and increase its feed_percent by 1. The coin can be empty if wanted
public fun feed_pet<T>(
  _auth: &AuthKey,
  uid: &mut UID,
  food: Coin<T>,
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
        feed_percent: 0,
        last_feed: 0,
        pet_id,
      },
    );
  };

  let feedable = dof::borrow_mut<FeedKey, FeedableAbility<T>>(uid, FeedKey {});

  // can only feed once per epoch
  assert!(ctx.epoch() > feedable.last_feed, EAlreadyFed);

  feedable.last_feed = ctx.epoch();
  feedable.feed_percent = feedable.feed_percent + 1;

  assert!(feedable.feed_percent <= 100, EMaxFeed);

  coin::put(&mut feedable.stomach, food);
}

public fun feed_suifren<Fren>(
  _auth: &AuthKey,
  pet: &mut SuiFren<Fren>,
  food: Coin<SUI>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();
  let uid_mut = pet.uid_mut();
  feed_pet(_auth, uid_mut, food, version, ctx);
}

public fun feed_vaporeon<T>(
  _auth: &AuthKey,
  pet: &mut Vaporeon,
  food: Coin<T>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();
  let uid_mut = pet.uid();
  feed_pet(_auth, uid_mut, food, version, ctx);
}

public fun feed_aresrpg<T>(
  _auth: &AuthKey,
  pet: &mut Item,
  food: Coin<T>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  assert!(pet.item_category() == b"pet".to_string(), ENotPet);
  feed_pet(_auth, pet.uid_mut(_auth), food, version, ctx);
}
