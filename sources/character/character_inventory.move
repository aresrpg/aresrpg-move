module aresrpg::character_inventory {

  use std::{
    string::{utf8, from_ascii, String},
    type_name::{Self, TypeName}
  };

  use sui::{
    kiosk::PurchaseCap,
    vec_set::{Self, VecSet}
  };

  use aresrpg::{
    item::Item,
    character::Character,
    version::Version,
    admin::AdminCap
  };

  // ╔════════════════ [ Constant ] ════════════════════════════════════════════ ]

  const EInvalidSLot: u64 = 1;
  const EInvalidItem: u64 = 2;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct EquipmentSettings<> has key, store {
    id: UID,
    allowed_types: VecSet<String>
  }

  fun init(ctx: &mut TxContext) {
    let settings = EquipmentSettings {
      id: object::new(ctx),
      allowed_types: vec_set::singleton(from_ascii(type_name::get<PurchaseCap<Item>>().into_string()))
    };

    transfer::share_object(settings);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  /// Allow a new type of NFT to be equipped onto a character.
  public fun admin_whitelist_type<T: key + store>(
    self: &mut EquipmentSettings,
    _admin: &AdminCap,
  ) {
    let name = type_name::get<PurchaseCap<T>>().into_string();
    self.allowed_types.insert(from_ascii(name));
  }

  public fun admin_remove_type<T: key + store>(
    self: &mut EquipmentSettings,
    _admin: &AdminCap,
  ) {
    let name = type_name::get<PurchaseCap<T>>().into_string();
    self.allowed_types.remove(&from_ascii(name));
  }

  // ╔════════════════ [ Package ] ════════════════════════════════════════════ ]

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun equip_item<T: key + store>(
    character: &mut Character,
    slot: String,
    item: PurchaseCap<T>,
    version: &Version,
    settings: &EquipmentSettings,
  ) {
    version.assert_latest();

    let name = from_ascii(type_name::get<T>().into_string());

    assert!(settings.allowed_types.contains(&name), EInvalidItem);
    assert!(item_slot_valid(slot), EInvalidSLot);

    let inventory = character.borrow_inventory_mut();

    inventory.add(slot, item);
  }

  public fun unequip_item<T: key + store>(
    character: &mut Character,
    slot: String,
    version: &Version,
  ): PurchaseCap<T> {
    version.assert_latest();

    assert!(item_slot_valid(slot), EInvalidSLot);

    let inventory = character.borrow_inventory_mut();

    inventory.remove(slot)
  }

  // ╔════════════════ [ Private ] ════════════════════════════════════════════ ]

  fun item_slot_valid(slot: String): bool {
    slot == utf8(b"hat") ||
    slot == utf8(b"amulet") ||
    slot == utf8(b"cloack") ||
    slot == utf8(b"left_ring") ||
    slot == utf8(b"right_ring") ||
    slot == utf8(b"belt") ||
    slot == utf8(b"boots") ||
    slot == utf8(b"pet") ||
    slot == utf8(b"weapon") ||
    slot == utf8(b"relic_1") ||
    slot == utf8(b"relic_2") ||
    slot == utf8(b"relic_3") ||
    slot == utf8(b"relic_4") ||
    slot == utf8(b"relic_5") ||
    slot == utf8(b"relic_6") ||
    slot == utf8(b"title")
  }

}