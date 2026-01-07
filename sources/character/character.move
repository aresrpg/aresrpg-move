module aresrpg::character;

use aresrpg::{
  auth,
  derived::AresRoot,
  events,
  protected_policy::AresRPG_TransferPolicy,
  string::contains_whitespace,
  version::Version
};
use std::string::{Self as std_string, utf8, String};
use sui::{
  derived_object,
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
const ENameTaken: u64 = 106;
const ENameInvalid: u64 = 107;

const MIN_COLOR_VALUE: u32 = 0;
const MAX_COLOR_VALUE: u32 = 16777215; // Equivalent to 0xFFFFFF

// ╔════════════════ [ Macros ] ═══════════════════════════════════════════════ ]

/// Validate field hasn't changed (optimistic locking)
macro fun validate_unchanged($current: _, $expected: _) {
  assert!($current == $expected, EInvalidUpdate)
}

/// Validate value is within range [min, max]
macro fun validate_range($value: _, $min: _, $max: _, $error: _) {
  assert!($value >= $min && $value <= $max, $error)
}

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
  /// Server's last signature (for verification of next update)
  last_signature: vector<u8>,
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

/// Update character fields including stats with two-layer security:
/// Layer 1: Signature verification (proves server approved these specific values)
/// Layer 2: Optimistic locking (last_* prevents stale writes)
public fun update_character(
  self: &mut Character,
  server_pubkey: vector<u8>,
  signature: vector<u8>,
  new_signature: vector<u8>,
  position: Option<String>,
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

  // Layer 1: Signature verification (GAS COST - Ed25519 + keccak256)
  // Build message from all arguments and verify server signature
  let mut verifier = auth::verifier();

  // Add character ID to message
  verifier.add(&self.id());

  // Add all update arguments to message (order matters!)
  if (position.is_some()) {
    verifier.add_string(position.borrow());
  };
  if (realm.is_some()) {
    verifier.add_string(realm.borrow());
    verifier.add_string(&last_realm);
  };
  if (experience.is_some()) {
    verifier.add(experience.borrow());
    verifier.add(&last_experience);
  };
  if (health.is_some()) {
    verifier.add(health.borrow());
  };
  if (soul.is_some()) {
    verifier.add(soul.borrow());
  };
  if (vitality.is_some()) {
    verifier.add(vitality.borrow());
    verifier.add(&last_vitality);
  };
  if (wisdom.is_some()) {
    verifier.add(wisdom.borrow());
    verifier.add(&last_wisdom);
  };
  if (strength.is_some()) {
    verifier.add(strength.borrow());
    verifier.add(&last_strength);
  };
  if (intelligence.is_some()) {
    verifier.add(intelligence.borrow());
    verifier.add(&last_intelligence);
  };
  if (chance.is_some()) {
    verifier.add(chance.borrow());
    verifier.add(&last_chance);
  };
  if (agility.is_some()) {
    verifier.add(agility.borrow());
    verifier.add(&last_agility);
  };
  if (available_points.is_some()) {
    verifier.add(available_points.borrow());
    verifier.add(&last_available_points);
  };

  // Add last signature to prevent replay attacks
  verifier.add_bytes(self.last_signature);

  // Verify server signature
  verifier.verify(server_pubkey, signature);

  // Layer 2: Optimistic locking (FREE - compare-and-swap)
  // For each field we want to update, check server was up to date with last value

  if (position.is_some()) {
    self.position = position.destroy_some();
  };

  if (realm.is_some()) {
    validate_unchanged!(self.realm, last_realm);
    self.realm = realm.destroy_some();
  };

  if (experience.is_some()) {
    validate_unchanged!(self.experience, last_experience);
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
    validate_unchanged!(self.vitality, last_vitality);
    self.vitality = vitality.destroy_some();
  };

  if (wisdom.is_some()) {
    validate_unchanged!(self.wisdom, last_wisdom);
    self.wisdom = wisdom.destroy_some();
  };

  if (strength.is_some()) {
    validate_unchanged!(self.strength, last_strength);
    self.strength = strength.destroy_some();
  };

  if (intelligence.is_some()) {
    validate_unchanged!(self.intelligence, last_intelligence);
    self.intelligence = intelligence.destroy_some();
  };

  if (chance.is_some()) {
    validate_unchanged!(self.chance, last_chance);
    self.chance = chance.destroy_some();
  };

  if (agility.is_some()) {
    validate_unchanged!(self.agility, last_agility);
    self.agility = agility.destroy_some();
  };

  if (available_points.is_some()) {
    validate_unchanged!(self.available_points, last_available_points);
    self.available_points = available_points.destroy_some();
  };

  // Store new signature for next update (prevents replay attacks)
  self.last_signature = new_signature;

  events::emit_character_update_event(self.id());
}

/// We use the protected policy to freely access the character and delete it.
/// Note: Character deletion should also require signature verification in production.
public fun delete(
  kiosk: &mut Kiosk,
  kiosk_cap: &KioskOwnerCap,
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
    inventory,
    ..,
  } = character;

  // prevent deletion of a character with items in inventory
  assert!(inventory.is_empty(), EInventoryNotEmpty);

  object::delete(id);
  events::emit_character_delete_event(character_id);
}

// ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

public fun new(
  kiosk: &mut Kiosk,
  kiosk_owner_cap: &KioskOwnerCap,
  root: &mut AresRoot,
  policy: &TransferPolicy<Character>,
  raw_name: String,
  classe: String,
  male: bool,
  color_1: u32,
  color_2: u32,
  color_3: u32,
  version: &Version,
) {
  verify_classe(classe);
  version.assert_latest();

  let name = raw_name.to_ascii().to_lowercase().to_string();
  let mut key_name = copy name;

  key_name.append(b"::character".to_string());

  assert!(!derived_object::exists(root.uid(), key_name), ENameTaken);
  assert!(std_string::length(&name) > 3 && std_string::length(&name) < 20, ENameInvalid);
  assert!(!contains_whitespace(name), ENameInvalid);
  validate_range!(color_1, MIN_COLOR_VALUE, MAX_COLOR_VALUE, EInvalidColor);

  let character_id = derived_object::claim(
    root.uid(),
    key_name,
  );

  let raw_character_id = character_id.to_inner();

  let sex = if (male) b"male".to_string() else b"female".to_string();

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
    last_signature: vector::empty(), // No signature yet for new characters
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

public(package) fun add_experience(self: &mut Character, experience: u32) {
  self.experience = self.experience + experience;
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

// ╔════════════════ [ Testing ] ═══════════════════════════════════════════════ ]

#[test_only]
/// Wrapper of module initializer for testing
public fun test_init(ctx: &mut TxContext) {
  init(CHARACTER {}, ctx);
}
