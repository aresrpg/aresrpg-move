module aresrpg::item {
  use sui::{
    tx_context::{sender},
    package,
    display
  };

  use std::string::{utf8, String};

  use aresrpg::{
    admin::{AdminCap}
  };

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

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
    /// todo: await enum support
    /// misc, consumable, relic, rune, mount
    /// helmet, cape, necklace, ring, belt, boots,
    /// bow, wand, staff, dagger, scythe, axe, hammer, shovel, sword, fishing_rod, pickaxe
    item_type: String,
    level: u8,
    damage: vector<Damage>,
    stats: Option<Statistics>
  }

  public struct ITEM has drop {}

  // ╔════════════════ [ Write ] ════════════════════════════════════════════ ]

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
  }

  public(package) fun mint(
    _: &AdminCap,
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