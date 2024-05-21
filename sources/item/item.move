module aresrpg::item {

  // This module allows access to item object creation,
  // and provide utilities to manage item fields.

  use sui::{
    tx_context::{sender},
    package,
    display,
    dynamic_field as dfield,
  };

  use std::string::{utf8, String};

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EWronItemType: u64 = 101;
  const EWrongAmount: u64 = 102;
  const ENotStackable: u64 = 103;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Item has key, store {
    id: UID,
    name: String,
    /// todo: await enum support
    /// misc, consumable, relic, rune, mount
    /// hat,
    /// cloack,
    /// amulet,
    /// ring,
    /// belt,
    /// boots,
    /// bow,
    /// wand,
    /// staff,
    /// dagger,
    /// scythe,
    /// axe,
    /// hammer,
    /// shovel,
    /// sword,
    /// fishing_rod,
    /// pickaxe,
    /// title,
    item_category: String,
    item_set: String,
    /// unique type (ex: reset_orb)
    item_type: String,
    level: u8,

    /// the amount of items in the stack
    /// this value can only be bigger than 1 if the item is stackable
    /// which means he has no stats nor damages
    amount: u32,
    /// weither the item is stackable or not
    /// if the item is stackable, it means it can be merged with other items
    /// otherwise the amount must always be 1
    stackable: bool
  }

  public struct ITEM has drop {}

  fun init(otw: ITEM, ctx: &mut TxContext) {
    let keys = vector[
        utf8(b"name"),
        utf8(b"link"),
        utf8(b"image_url"),
        utf8(b"description"),
        utf8(b"project_url"),
        utf8(b"creator")
    ];

    let values = vector[
        utf8(b"{name}"),
        utf8(b"https://app.aresrpg.world"),
        utf8(b"http://assets.aresrpg.world/item/{item_type}.png"),
        utf8(b"Item part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
        utf8(b"AresRPG")
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Item>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun amount(self: &Item): u32 {
    self.amount
  }

  public fun stackable(self: &Item): bool {
    self.stackable
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  public(package) fun new(
    name: String,
    item_category: String,
    item_set: String,
    item_type: String,
    level: u8,
    amount: u32,
    stackable: bool,
    ctx: &mut TxContext
  ): Item {

    if(amount > 1) {
      // if the item has an amount greater than 1, it must be stackable
      assert!(stackable, ENotStackable);
    };

    Item {
      id: object::new(ctx),
      name,
      item_category,
      item_set,
      item_type,
      level,
      amount,
      stackable
    }
  }

  public(package) fun destroy(self: Item) {
    let Item {
      id,
      name: _,
      item_category: _,
      item_set: _,
      item_type: _,
      level: _,
      amount: _,
      stackable: _
    } = self;

    object::delete(id);
  }

  /// A helper to check if the item type id is correct
  public(package) fun assert_item_type(self: &Item, item_type: vector<u8>) {
    assert!(self.item_type == utf8(item_type), EWronItemType);
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

  /// Some items like simple wood (to make sturdy sui tables) can be stacked
  /// to avoid minting thousands of objects.
  public(package) fun split(
    self: &mut Item,
    amount: u32,
    ctx: &mut TxContext
  ): Item {
    // the split amount must be at least 1
    assert!(amount >= 1, EWrongAmount);
    // the item amount must be above the split amount (so 2 or more)
    assert!(self.amount > amount, EWrongAmount);
    // the item must be stackable
    assert!(self.stackable, ENotStackable);

    let new_item = new(
      self.name,
      self.item_category,
      self.item_set,
      self.item_type,
      self.level,
      amount,
      true,
      ctx
    );

    self.amount = self.amount - amount;

    new_item
  }

  public(package) fun merge(
    self: &mut Item,
    item: Item,
  ) {
    // the item must be stackable
    assert!(self.stackable, ENotStackable);
    // the item must be the same type
    assert!(self.item_type == item.item_type, EWronItemType);

    self.amount = self.amount + item.amount;

    item.destroy();
  }
}