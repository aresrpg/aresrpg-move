module aresrpg::item_recipe;

use aresrpg::{
  auth::AuthKey,
  events,
  item::{Self, Item},
  item_damages::{Self, ItemDamages},
  item_stats::{Self, ItemStatistics},
  version::Version
};
use std::string::String;
use sui::{
  kiosk::{Kiosk, KioskOwnerCap},
  random::{Random, new_generator},
  transfer_policy::TransferPolicy
};

/// This module allows using specific items to generate new ones through Sui's randomness

// ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

/// This object is obtained when using a item of type recipe_scroll
/// It stays on the address, indicating the user is able to craft the item
public struct Recipe has key {
  id: UID,
  recipe_type: String,
}

/// This object is obtained when crafting an item, it is used to "reveal" the item
public struct FinishedCraft has key {
  id: UID,
  template: ItemTemplate,
}

/// Template to mint an item randomly with stats and damages
public struct ItemTemplate has store, drop {
  name: String,
  item_category: String,
  item_set: String,
  item_type: String,
  level: u8,
  stats_min: ItemStatistics,
  stats_max: ItemStatistics,
  damages: vector<ItemDamages>,
}

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

/// Craft the item from the finished craft proof
entry fun craft_item(
  craft: FinishedCraft,
  random: &Random,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  policy: &TransferPolicy<Item>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let FinishedCraft {
    id,
    template,
  } = craft;

  events::emit_item_destroy_event(id.to_inner());

  id.delete();

  let crafted_item = item_from_template(
    &template,
    1, // we craft one by one, why do you want to craft faster anyway? it's not like you have anything else to do
    random,
    ctx,
  );

  events::emit_item_mint_event(
    object::id(&crafted_item),
    object::id(kiosk),
  );

  kiosk.lock(kiosk_cap, policy, crafted_item);
}

public fun create_template(
  _auth: &AuthKey,
  name: String,
  item_category: String,
  item_set: String,
  item_type: String,
  level: u8,
  stats_min: ItemStatistics,
  stats_max: ItemStatistics,
  damages: vector<ItemDamages>,
): ItemTemplate {
  ItemTemplate {
    name,
    item_category,
    item_set,
    item_type,
    level,
    stats_min,
    stats_max,
    damages,
  }
}

public fun create_recipe(_auth: &AuthKey, recipe_type: String, ctx: &mut TxContext) {
  transfer::transfer(
    Recipe {
      id: object::new(ctx),
      recipe_type,
    },
    ctx.sender(),
  )
}

public fun create_finished_craft(_auth: &AuthKey, template: ItemTemplate, ctx: &mut TxContext) {
  transfer::transfer(
    FinishedCraft {
      id: object::new(ctx),
      template,
    },
    ctx.sender(),
  )
}

// ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

public(package) fun item_from_template(
  template: &ItemTemplate,
  amount: u32,
  random: &Random,
  ctx: &mut TxContext,
): Item {
  let mut item = item::new(
    template.name,
    template.item_category,
    template.item_set,
    template.item_type,
    template.level,
    amount,
    amount > 1,
    ctx,
  );

  let mut generator = new_generator(random, ctx);

  // all paths consume the same (@see https://docs.sui.io/guides/developer/advanced/randomness-onchain)
  let stats = item_stats::new(
    generator.generate_u16_in_range(
      template.stats_min.vitality(),
      template.stats_max.vitality(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.wisdom(),
      template.stats_max.wisdom(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.strength(),
      template.stats_max.strength(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.intelligence(),
      template.stats_max.intelligence(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.chance(),
      template.stats_max.chance(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.agility(),
      template.stats_max.agility(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.range(),
      template.stats_max.range(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.movement(),
      template.stats_max.movement(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.action(),
      template.stats_max.action(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.critical(),
      template.stats_max.critical(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.raw_damage(),
      template.stats_max.raw_damage(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.critical_chance(),
      template.stats_max.critical_chance(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.critical_outcomes(),
      template.stats_max.critical_outcomes(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.earth_resistance(),
      template.stats_max.earth_resistance(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.fire_resistance(),
      template.stats_max.fire_resistance(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.water_resistance(),
      template.stats_max.water_resistance(),
    ),
    generator.generate_u16_in_range(
      template.stats_min.air_resistance(),
      template.stats_max.air_resistance(),
    ),
  );

  item_stats::augment_with_stats(&mut item, stats);

  if (template.damages.length() > 0) {
    item_damages::augment_with_damages(&mut item, template.damages);
  };

  item
}
