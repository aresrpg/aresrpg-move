module aresrpg::item {
  use sui::tx_context::{sender};
  use std::string::{utf8, String};
  use sui::package;
  use sui::display;

  #[allow(unused_field)]
  public struct Damage has store {
    from: u16,
    to: u16,
    damage_type: String,
    element: String
  }

  #[allow(unused_field)]
  public struct Statistics has store {
    vitality: u16,
    wisdom: u16,
    strength: u16,
    intelligence: u16,
    chance: u16,
    agility: u16,
    range: u8,
    movement: u8,
    action: u8,
    critical: u8,
    critical_chance: u8,
    critical_outcomes: u8,
  }

  public struct Item has key, store {
    id: UID,
    name: String,
    item_type: String,
    level: u8,
    damage: vector<Damage>,
    stats: Option<Statistics>
  }

  public struct ItemMintCap has key {
    id: UID,
  }

  public struct ITEM has drop {}

  fun init(otw: ITEM, ctx: &mut TxContext) {
    let keys = vector[
        utf8(b"name"),
        utf8(b"link"),
        utf8(b"image_url"),
        utf8(b"description"),
        utf8(b"project_url"),
    ];

    let values = vector[
        utf8(b"{name}"),
        utf8(b"https://aresrpg.world/item/{type}"),
        utf8(b"https://aresrpg.world/item/{type}.png"),
        utf8(b"Item part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Item>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
    transfer::transfer(ItemMintCap { id: object::new(ctx) }, sender(ctx))
  }

  public fun mint(
    _: &ItemMintCap,
    name: String,
    item_type: String,
    level: u8,
    damage: vector<Damage>,
    stats: Option<Statistics>,
    ctx: &mut TxContext
  ): Item {
    Item {
      id: object::new(ctx),
      name,
      item_type,
      level,
      damage,
      stats
    }
  }
}