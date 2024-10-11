module aresrpg::item_sale {

  // This module allows setting up global sales for items

  use sui::{
    coin::Coin,
    sui::SUI,
    balance::{Balance, zero},
    kiosk::Kiosk,
    transfer_policy::TransferPolicy,
    random::Random,
    kiosk_extension,
    tx_context::sender
  };

  use aresrpg::{
    item::Item,
    item_recipe::{ItemTemplate, item_from_template},
    admin::AdminCap,
    version::Version,
    extension::AresRPG,
    events,
  };

  use kiosk::{
    personal_kiosk::PersonalKioskCap
  };

  // ╔════════════════ [ Constants ] ════════════════════════════════════════════ ]

  const EWrongPayment: u64 = 101;
  const EExtensionNotInstalled: u64 = 102;
  const EOutOfStock: u64 = 103;

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  /// Shared object representing an item sale
  public struct ItemSale has key, store {
    id: UID,
    price: u64,
    amount: u32, // the amount (stack) of the single item, you could buy 1 item of 100 wood
    stock: u64,
    template: ItemTemplate,
    profits: Balance<SUI>
  }

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  /// Buy an item from the stock
  /// Randomly generate stats according to the sale template
  entry fun buy_item(
    sale: &mut ItemSale,
    coin: Coin<SUI>,
    random: &Random,
    kiosk: &mut Kiosk,
    personal_kiosk_cap: &mut PersonalKioskCap,
    policy: &TransferPolicy<Item>,
    version: &Version,
    ctx: &mut TxContext
  ) {
    version.assert_latest();

    assert!(sale.price == coin.value(), EWrongPayment);
    assert!(kiosk_extension::is_installed<AresRPG>(kiosk), EExtensionNotInstalled);
    assert!(sale.stock > 0, EOutOfStock);

    sale.stock = sale.stock - 1;
    sale.profits.join(coin.into_balance());

    let item = item_from_template(
      &sale.template,
      sale.amount,
      random,
      ctx
    );

    events::emit_item_mint_event(
      object::id(&item),
      object::id(kiosk),
    );

    let kiosk_cap = personal_kiosk_cap.borrow_mut();

    kiosk.lock(kiosk_cap, policy, item);
  }

  // ╔════════════════ [ Admin ] ════════════════════════════════════════════ ]

  public fun admin_create_sale(
    admin: &AdminCap,
    template: ItemTemplate,
    price: u64,
    amount: u32,
    stock: u64,
    ctx: &mut TxContext
  ) {
    admin.verify(ctx);

    let id = object::new(ctx);

    events::emit_sale_create_event(id.uid_to_inner());

    transfer::share_object(ItemSale {
      id,
      price,
      amount,
      stock,
      template,
      profits: zero()
    });
  }

  public fun admin_delete_sale(
    admin: &AdminCap,
    recipe: ItemSale,
    ctx: &mut TxContext
  ): Coin<SUI> {
    admin.verify(ctx);

    let ItemSale {
      id,
      profits,
      ..
    } = recipe;

    events::emit_sale_delete_event(id.uid_to_inner());

    id.delete();
    profits.into_coin(ctx)
  }

  public fun admin_withdraw_profits(
    admin: &AdminCap,
    sale: &mut ItemSale,
    ctx: &mut TxContext
  ): Coin<SUI> {
    admin.verify(ctx);
    sale.profits.withdraw_all().into_coin(ctx)
  }
}