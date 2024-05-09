module aresrpg::item {
  use sui::{
    tx_context::{sender},
    package,
    display,
    dynamic_field as dfield,
  };

  use std::string::{utf8, String};

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EWronItemType: u64 = 1;
  const EWronItemCategory: u64 = 2;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Item has key, store {
    id: UID,
    name: String,
    /// todo: await enum support
    /// misc, consumable, relic, rune, mount
    /// hat, cloack, amulet, ring, belt, boots,
    /// bow, wand, staff, dagger, scythe, axe, hammer, shovel, sword, fishing_rod, pickaxe
    item_category: String,
    /// unique type (ex: reset_orb)
    item_type: String,
    level: u8,
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
        utf8(b"https://app.aresrpg.world/item/{type}"),
        utf8(b"https://app.aresrpg.world/item/{type}.jpg"),
        utf8(b"Item part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Item>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun new(
    name: String,
    item_category: String,
    item_type: String,
    level: u8,
    ctx: &mut TxContext
  ): Item {
    Item {
      id: object::new(ctx),
      name,
      item_category,
      item_type,
      level,
    }
  }

  public(package) fun destroy(self: Item) {
    let Item {
      id,
      name: _,
      item_category: _,
      item_type: _,
      level: _,
    } = self;

    object::delete(id);
  }

  public(package) fun add_field<Key: copy + drop + store, Value: store>(
    self: &mut Item,
    key: Key,
    value: Value,
  ) {
    dfield::add(&mut self.id, key, value);
  }

  public(package) fun has_field<Key: copy + drop + store>(
    self: &Item,
    key: Key
  ): bool {
    dfield::exists_(&self.id, key)
  }

  public(package) fun borrow_field_mut<Key: copy + drop + store, Value: store>(
    self: &mut Item,
    key: Key,
  ): &mut Value {
    dfield::borrow_mut<Key, Value>(&mut self.id, key)
  }

  public(package) fun borrow_field<Key: copy + drop + store, Value: store>(
    self: &Item,
    key: Key,
  ): &Value {
    dfield::borrow<Key, Value>(&self.id, key)
  }

  public(package) fun clone(self: &Item, ctx: &mut TxContext): Item {
    Item {
      id: object::new(ctx),
      name: self.name,
      item_category: self.item_category,
      item_type: self.item_type,
      level: self.level,
    }
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun assert_item_category(self: &Item, item_category: vector<u8>) {
    assert!(self.item_category == utf8(item_category), EWronItemCategory);
  }
}