module aresrpg::character;

use aresrpg::{
  auth::AuthKey,
  character_registry::NameRegistry,
  events,
  protected_policy::AresRPG_TransferPolicy,
  version::Version
};
use std::string::{utf8, String};
use sui::{
  display,
  dynamic_field as dfield,
  kiosk::{Kiosk, KioskOwnerCap},
  package,
  transfer_policy::TransferPolicy,
  tx_context::sender,
  vec_map::{Self, VecMap}
};

// ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

const EInventoryNotEmpty: u64 = 101;
const EExperienceTooLow: u64 = 102;
const EInvalidClasse: u64 = 103;
const EInvalidColor: u64 = 104;
const EInvalidUpdate: u64 = 105;

const MIN_COLOR_VALUE: u32 = 0;
const MAX_COLOR_VALUE: u32 = 16777215; // Equivalent to 0xFFFFFF

// ╔════════════════ [ Type ] ════════════════════════════════════════════════ ]

public struct Character has key, store {
  id: UID,
  name: String,
  classe: String,
  sex: String,
  realm: String,
  position: String,
  experience: u32,
  health: u16,
  soul: u8,
  inventory: VecMap<String, ID>,
  color_1: u32,
  color_2: u32,
  color_3: u32,
  vitality: u16,
  wisdom: u16,
  strength: u16,
  intelligence: u16,
  chance: u16,
  agility: u16,
  available_points: u16,
}

// one time witness
public struct CHARACTER has drop {}

// ╔════════════════ [ init ] ════════════════════════════════════════════ ]

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
  let mut display = display::new_with_fields<Character>(
    &publisher,
    keys,
    values,
    ctx,
  );

  display::update_version(&mut display);

  transfer::public_transfer(publisher, sender(ctx));
  transfer::public_transfer(display, sender(ctx));
}

// ╔════════════════ [ Protected ] ════════════════════════════════════════════ ]

/// Update character fields including stats
public fun update_character(
  _auth: &AuthKey,
  self: &mut Character,
  position: Option<String>,
  last_position: String,
  realm: Option<String>,
  last_realm: String,
  experience: Option<u32>,
  last_experience: u32,
  health: Option<u16>,
  soul: Option<u8>,
  vitality: Option<u16>,
  last_vitality: u16,
  wisdom: Option<u16>,
  last_wisdom: u16,
  strength: Option<u16>,
  last_strength: u16,
  intelligence: Option<u16>,
  last_intelligence: u16,
  chance: Option<u16>,
  last_chance: u16,
  agility: Option<u16>,
  last_agility: u16,
  available_points: Option<u16>,
  last_available_points: u16,
  version: &Version,
) {
  version.assert_latest();

  // For each field we want to update
  // We check that the server was up to date with the last value

  if (position.is_some()) {
    assert!(self.position == last_position, EInvalidUpdate);
    self.position = position.destroy_some();
  };

  if (realm.is_some()) {
    assert!(self.realm == last_realm, EInvalidUpdate);
    self.realm = realm.destroy_some();
  };

  if (experience.is_some()) {
    assert!(self.experience == last_experience, EInvalidUpdate);
    let experience = experience.destroy_some();
    assert!(experience > self.experience, EExperienceTooLow);
    self.experience = experience;
  };

  if (health.is_some()) {
    self.health = health.destroy_some();
  };

  if (soul.is_some()) {
    self.soul = soul.destroy_some();
  };

  if (vitality.is_some()) {
    assert!(self.vitality == last_vitality, EInvalidUpdate);
    self.vitality = vitality.destroy_some();
  };

  if (wisdom.is_some()) {
    assert!(self.wisdom == last_wisdom, EInvalidUpdate);
    self.wisdom = wisdom.destroy_some();
  };

  if (strength.is_some()) {
    assert!(self.strength == last_strength, EInvalidUpdate);
    self.strength = strength.destroy_some();
  };

  if (intelligence.is_some()) {
    assert!(self.intelligence == last_intelligence, EInvalidUpdate);
    self.intelligence = intelligence.destroy_some();
  };

  if (chance.is_some()) {
    assert!(self.chance == last_chance, EInvalidUpdate);
    self.chance = chance.destroy_some();
  };

  if (agility.is_some()) {
    assert!(self.agility == last_agility, EInvalidUpdate);
    self.agility = agility.destroy_some();
  };

  if (available_points.is_some()) {
    assert!(self.available_points == last_available_points, EInvalidUpdate);
    self.available_points = available_points.destroy_some();
  };
}

/// We use the protected policy to freely access the character and delete it.
/// This function also requires the server's signature to ensure the deletion is authorized.
/// Hence preventing abuse of sponsored gas storage fees.
public fun delete(
  _auth: &AuthKey,
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
  name_registry: &mut NameRegistry,
  character_id: ID,
  policy: &AresRPG_TransferPolicy<Character>,
  version: &Version,
  ctx: &mut TxContext,
) {
  version.assert_latest();

  let character = policy.extract_from_kiosk<Character>(
    kiosk,
    kiosk_cap,
    character_id,
    ctx,
  );

  let Character {
    id,
    name,
    inventory,
    ..,
  } = character;

  // prevent deletion of a character with items in inventory
  assert!(inventory.is_empty(), EInventoryNotEmpty);

  name_registry.remove_name(name);

  object::delete(id);
  events::emit_character_delete_event(character_id);
}

// ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

public fun new(
  kiosk: &mut Kiosk,
  kiosk_owner_cap: &KioskOwnerCap,
  name_registry: &mut NameRegistry,
  policy: &TransferPolicy<Character>,
  raw_name: String,
  classe: String,
  male: bool,
  color_1: u32,
  color_2: u32,
  color_3: u32,
  version: &Version,
  ctx: &mut TxContext,
) {
  verify_classe(classe);
  version.assert_latest();

  let character_id = object::new(ctx);
  let raw_character_id = character_id.to_inner();

  assert!(color_1 >= MIN_COLOR_VALUE && color_1 <= MAX_COLOR_VALUE, EInvalidColor);

  let name = raw_name.to_ascii().to_lowercase().to_string();
  let sex = if (male) b"male".to_string() else b"female".to_string();

  name_registry.add_name(name, ctx);

  let character = Character {
    id: character_id,
    name,
    position: b"{\"x\":0,\"y\":0,\"z\":0}".to_string(),
    realm: b"overworld".to_string(),
    experience: 0,
    classe,
    sex,
    health: 30,
    soul: 100,
    inventory: vec_map::empty(),
    color_1,
    color_2,
    color_3,
    vitality: 0,
    wisdom: 0,
    strength: 0,
    intelligence: 0,
    chance: 0,
    agility: 0,
    available_points: 0,
  };

  kiosk.lock<Character>(kiosk_owner_cap, policy, character);

  events::emit_character_create_event(
    raw_character_id,
    object::id(kiosk),
  );
}

// ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

public(package) fun add_field<Key: copy + drop + store, Value: store>(
  self: &mut Character,
  key: Key,
  value: Value,
) {
  dfield::add(&mut self.id, key, value);
}

public(package) fun has_field<Key: copy + drop + store>(self: &Character, key: Key): bool {
  dfield::exists_(&self.id, key)
}

public(package) fun borrow_field_mut<Key: copy + drop + store, Value: store>(
  self: &mut Character,
  key: Key,
): &mut Value {
  dfield::borrow_mut<Key, Value>(&mut self.id, key)
}

public(package) fun borrow_inventory_mut(self: &mut Character): &mut VecMap<String, ID> {
  &mut self.inventory
}

public(package) fun id(self: &Character): ID {
  self.id.to_inner()
}

public(package) fun uid_mut(self: &mut Character): &mut UID {
  &mut self.id
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
    EInvalidClasse,
  );
}
