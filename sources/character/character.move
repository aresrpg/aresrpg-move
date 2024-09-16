module aresrpg::character {

  // This module is the base character entity,
  // it is used to initiate characters and manage their core datas.

  use sui::{
    tx_context::{sender},
    package,
    display,
    dynamic_field as dfield,
    object_bag::{Self, ObjectBag},
  };

  use std::string::{utf8, String};

  use aresrpg::{
    character_registry::{NameRegistry},
    admin::{AdminCap},
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EInventoryNotEmpty: u64 = 101;
  const EExperienceTooLow: u64 = 102;
  const EInvalidClasse: u64 = 103;

  // ╔════════════════ [ Type ] ════════════════════════════════════════════ ]

  public struct Character has key, store {
    id: UID,
    name: String,
    classe: String,
    sex: String,
    realm: String,

    position: String,
    experience: u32,
    health: u16,

    // Easier to know in what kiosk the character is as moving it to the extension break
    // the direct ownership link because of dynamic fields
    selected_in: String,

    // Represent the energy left, it goes down on death
    soul: u8,
    inventory: ObjectBag,
  }


  // one time witness
  public struct CHARACTER has drop {}

  fun init(otw: CHARACTER, ctx: &mut TxContext) {
    let keys = vector[
        utf8(b"name"),
        utf8(b"link"),
        utf8(b"image_url"),
        utf8(b"description"),
        utf8(b"project_url"),
        utf8(b"creator"),
    ];

    let values = vector[
        utf8(b"{name}"),
        utf8(b"https://app.aresrpg.world"),
        utf8(b"https://assets.aresrpg.world/classe/{classe}_{sex}.jpg"),
        utf8(b"Character part of the AresRPG universe."),
        utf8(b"https://aresrpg.world"),
        utf8(b"AresRPG"),
    ];

    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Character>(&publisher, keys, values, ctx);

    display::update_version(&mut display);

    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun borrow_inventory(self: &Character): &ObjectBag {
    &self.inventory
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Set the position of a character
  public fun admin_set_position(
    self: &mut Character,
    admin: &AdminCap,
    position: String,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    self.position = position;
  }

  public fun admin_set_health(
    self: &mut Character,
    admin: &AdminCap,
    health: u16,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    self.health = health;
  }

  public fun admin_set_soul(
    self: &mut Character,
    admin: &AdminCap,
    soul: u8,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    self.soul = soul;
  }

  /// Add experience to a character
  public fun admin_set_experience(
    self: &mut Character,
    admin: &AdminCap,
    experience: u32,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    assert!(experience > self.experience, EExperienceTooLow);
    self.experience = experience;
  }

  public fun admin_set_realm(
    self: &mut Character,
    admin: &AdminCap,
    realm: String,
    ctx: &TxContext
  ) {
    admin.verify(ctx);
    self.realm = realm;
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  /// Create a new character, and add it to the name registry
  public(package) fun new(
    name_registry: &mut NameRegistry,
    raw_name: String,
    classe: String,
    male: bool,
    ctx: &mut TxContext
  ): Character {
    verify_classe(classe);

    let name = raw_name.to_ascii().to_lowercase().to_string();
    let sex = if(male) b"male".to_string() else b"female".to_string();

    name_registry.add_name(name, ctx);

    Character {
      id: object::new(ctx),
      name,
      position: b"{\"x\":0,\"y\":0,\"z\":0}".to_string(),
      realm: b"overworld".to_string(),
      experience: 0,
      classe,
      sex,
      health: 30,
      selected_in: b"".to_string(),
      soul: 100,
      inventory: object_bag::new(ctx)
    }
  }

  public(package) fun delete(
    character: Character,
    name_registry: &mut NameRegistry,
  ) {
    let Character {
      id,
      name,
      inventory,
      ..
    } = character;
    // prevent deletion of a character with items in inventory
    assert!(inventory.is_empty(), EInventoryNotEmpty);

    inventory.destroy_empty();
    name_registry.remove_name(name);

    object::delete(id);
  }

  public(package) fun add_field<Key: copy + drop + store, Value: store>(
    self: &mut Character,
    key: Key,
    value: Value,
  ) {
    dfield::add(&mut self.id, key, value);
  }

  public(package) fun has_field<Key: copy + drop + store>(
    self: &Character,
    key: Key
  ): bool {
    dfield::exists_(&self.id, key)
  }

  public(package) fun borrow_field_mut<Key: copy + drop + store, Value: store>(
    self: &mut Character,
    key: Key,
  ): &mut Value {
    dfield::borrow_mut<Key, Value>(&mut self.id, key)
  }

  public(package) fun borrow_inventory_mut(self: &mut Character): &mut ObjectBag {
    &mut self.inventory
  }

  public(package) fun set_selected_in(self: &mut Character, kiosk_id: String) {
    self.selected_in = kiosk_id;
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun verify_classe(classe: String) {
    assert!(
      classe == b"shugo".to_string() ||
      classe == b"tomoda".to_string() ||
      classe == b"rojin".to_string() ||
      classe == b"yajin".to_string() ||
      classe == b"tokei".to_string() ||
      classe == b"asobi".to_string() ||
      classe == b"tsuba".to_string() ||
      classe == b"senshi".to_string() ||
      classe == b"yogan".to_string() ||
      classe == b"mori".to_string() ||
      classe == b"ikari".to_string() ||
      classe == b"shusen".to_string(),
      EInvalidClasse
    );
  }
}