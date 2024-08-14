module aresrpg::item_recipe {

  use std::{
    string::{substring, String},
    type_name,
  };

  use sui::{
    coin::Coin,
    kiosk::{Kiosk, KioskOwnerCap},
    transfer_policy::TransferPolicy,
    random::{Random, new_generator},
    kiosk_extension,
    tx_context::sender
  };

  use aresrpg::{
    item::{Self, Item, ItemCategory},
    admin::AdminCap,
    item_stats::{Self, ItemStatistics},
    item_damages::{Self, ItemDamages},
    version::Version,
    extension::AresRPG,
    protected_policy::AresRPG_TransferPolicy,
    events,
  };

  use kiosk::{
    personal_kiosk::PersonalKioskCap
  };

  // ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

  const EWrongRecipe: u64 = 101;
  const EExtensionNotInstalled: u64 = 102;
  const ERecipeIncomplete: u64 = 103;
  const EWrongIngredient: u64 = 104;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  /// an ingredient contains the type of an item or a token, and can be used to craft
  public struct Ingredient has store, copy, drop {
    // could be an aresrpg item type, or a real token type T
    item_type: String,
    name: String,
    amount: u64
  }

  /// Template to mint an item randomly with stats and damages
  public struct ItemTemplate has store, drop {
    name: String,
    item_category: ItemCategory,
    item_set: String,
    item_type: String,
    level: u8,

    stats_min: ItemStatistics,
    stats_max: ItemStatistics,
    damages: vector<ItemDamages>,
  }

  /// Shared object representing a recipe to craft an item
  public struct Recipe has key, store {
    id: UID,
    level: u8,
    ingredients: vector<Ingredient>,
    template: ItemTemplate
  }

  /// hot potato to follow the process of crafting an item
  /// all ingredients must be consumed
  public struct Craft {
    recipe_id: ID,
    ingredients: vector<Ingredient>,
  }

  // finished craft object which can be minted as an item with random stats
  // according to the recipe template
  // this is required as randomness transactions must be an entry and can't use the potato
  public struct FinishedCraft has key {
    id: UID,
    recipe_id: ID,
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Start the crafting process by issuing a hot potato from a recipe
  public fun start_craft(
    recipe: &Recipe,
    version: &Version,
  ): Craft {
    version.assert_latest();

    Craft {
      recipe_id: recipe.id.uid_to_inner(),
      ingredients: recipe.ingredients,
    }
  }

  // No need to check version since this is always a following of the start_craft
  /// Consume a token ingredient
  public fun use_token_ingredient<T>(
    coin: Coin<T>,
    craft: &mut Craft,
  ) {
    let mut i = 0;
    let mut used = false;

    while (i < craft.ingredients.length()) {
      let ingredient = craft.ingredients[i];
      let parsed_type = substring(&ingredient.item_type, 2, ingredient.item_type.length());

      if(type_name::get<T>().into_string() == parsed_type.to_ascii()) {
        assert!(coin.value() == ingredient.amount, EWrongIngredient);
        craft.ingredients.remove(i);
        used = true;
        break
      };

      i = i + 1
    };

    assert!(used, EWrongIngredient);

    transfer::public_transfer(coin, @0x0);
  }

  // No need to check version since this is always a following of the start_craft
  /// Consume an aresrpg item ingredient
  public fun use_item_ingredient(
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    item_id: ID,
    protected_policy: &AresRPG_TransferPolicy<Item>,
    craft: &mut Craft,
    ctx: &mut TxContext
  ) {
    let item = protected_policy.extract_from_kiosk(
      kiosk,
      kiosk_cap,
      item_id,
      ctx
    );

    let mut i = 0;
    let mut used = false;

    while (i < craft.ingredients.length()) {
      let ingredient = craft.ingredients[i];

      if(ingredient.item_type == item.item_type()) {
        assert!(ingredient.amount == item.amount() as u64, EWrongIngredient);
        used = true;
        craft.ingredients.remove(i);
        break
      };

      i = i + 1;
    };

    assert!(used, EWrongIngredient);

    item.destroy();
  }

  /// Retrieve a proof of craft completion to be used in the final step
  /// when all ingredients have been used.
  /// Consume the craft hot potato
  public fun prove_all_ingredients_used(craft: Craft, ctx: &mut TxContext) {
    let Craft {
      recipe_id,
      ingredients,
    } = craft;

    assert!(ingredients.length() == 0, ERecipeIncomplete);

    let finished = FinishedCraft {
      id: object::new(ctx),
      recipe_id,
    };

    events::emit_finished_craft_event(object::id(&finished), recipe_id);

    transfer::transfer(finished, sender(ctx));
  }

  /// Craft the item from the finished craft proof
  /// Randomly generate stats according to the recipe template
  entry fun craft_item(
    recipe: &Recipe,
    craft: FinishedCraft,
    random: &Random,
    kiosk: &mut Kiosk,
    personal_kiosk_cap: &mut PersonalKioskCap,
    policy: &TransferPolicy<Item>,
    version: &Version,
    ctx: &mut TxContext
  ) {
    version.assert_latest();

    let FinishedCraft {
      id,
      recipe_id,
    } = craft;

    events::emit_item_destroy_event(id.to_inner());

    id.delete();

    assert!(recipe_id == recipe.id.uid_as_inner(), EWrongRecipe);
    assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);

    let mut generator = new_generator(random, ctx);

    let mut crafted_item = item::new(
      recipe.template.name,
      recipe.template.item_category,
      recipe.template.item_set,
      recipe.template.item_type,
      recipe.template.level,
      1,
      false,
      ctx
    );

    // all paths consume the same (@see https://docs.sui.io/guides/developer/advanced/randomness-onchain)
    let stats = item_stats::new(
      generator.generate_u16_in_range(
        recipe.template.stats_min.vitality(),
        recipe.template.stats_max.vitality()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.wisdom(),
        recipe.template.stats_max.wisdom()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.strength(),
        recipe.template.stats_max.strength()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.intelligence(),
        recipe.template.stats_max.intelligence()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.chance(),
        recipe.template.stats_max.chance()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.agility(),
        recipe.template.stats_max.agility()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.range(),
        recipe.template.stats_max.range()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.movement(),
        recipe.template.stats_max.movement()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.action(),
        recipe.template.stats_max.action()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.critical(),
        recipe.template.stats_max.critical()),
      generator.generate_u16_in_range(
        recipe.template.stats_min.raw_damage(),
        recipe.template.stats_max.raw_damage()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.critical_chance(),
        recipe.template.stats_max.critical_chance()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.critical_outcomes(),
        recipe.template.stats_max.critical_outcomes()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.earth_resistance(),
        recipe.template.stats_max.earth_resistance()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.fire_resistance(),
        recipe.template.stats_max.fire_resistance()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.water_resistance(),
        recipe.template.stats_max.water_resistance()),
      generator.generate_u8_in_range(
        recipe.template.stats_min.air_resistance(),
        recipe.template.stats_max.air_resistance())
    );

    item_stats::augment_with_stats(&mut crafted_item, stats);

    if(recipe.template.damages.length() > 0) {
      item_damages::augment_with_damages(&mut crafted_item, recipe.template.damages);
    };

    events::emit_item_mint_event(
      object::id(&crafted_item),
      object::id(kiosk),
    );

    let kiosk_cap = personal_kiosk_cap.borrow_mut();

    kiosk.lock(kiosk_cap, policy, crafted_item);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  public fun admin_create_recipe(
    admin: &AdminCap,
    level: u8,
    ingredients: vector<Ingredient>,
    template: ItemTemplate,
    ctx: &mut TxContext
  ) {
    admin.verify(ctx);

    let id = object::new(ctx);

    events::emit_recipe_create_event(id.uid_to_inner());

    transfer::share_object(Recipe {
      id,
      level,
      ingredients,
      template
    });
  }

  public fun admin_delete_recipe(
    admin: &AdminCap,
    recipe: Recipe,
    ctx: &mut TxContext
  ) {
    admin.verify(ctx);

    let Recipe {
      id,
      level: _,
      ingredients: _,
      template: _
    } = recipe;

    events::emit_recipe_delete_event(id.uid_to_inner());

    object::delete(id);
  }

  public fun admin_create_ingredient(
    admin: &AdminCap,
    item_type: String,
    amount: u64,
    name: String,
    ctx: &mut TxContext
  ): Ingredient {
    admin.verify(ctx);

    Ingredient {
      item_type,
      amount,
      name
    }
  }

  public fun admin_create_template(
    admin: &AdminCap,
    name: String,
    item_category: ItemCategory,
    item_set: String,
    item_type: String,
    level: u8,
    stats_min: ItemStatistics,
    stats_max: ItemStatistics,
    damages: vector<ItemDamages>,
    ctx: &mut TxContext
  ): ItemTemplate {
    admin.verify(ctx);

    ItemTemplate {
      name,
      item_category,
      item_set,
      item_type,
      level,
      stats_min,
      stats_max,
      damages
    }
  }
}