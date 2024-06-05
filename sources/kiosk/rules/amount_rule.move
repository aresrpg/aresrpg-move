module aresrpg::amount_rule {
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };

    use aresrpg::item::Item;

    const EWrongAmount: u64 = 101;
    const EWrongItem: u64 = 102;

    public struct Rule has drop {}

    public struct Config has store, drop {}

    public fun add(
      policy: &mut TransferPolicy<Item>,
      cap: &TransferPolicyCap<Item>
    ) {
        policy::add_rule(Rule {}, policy, cap, Config {})
    }

    public fun prove(
      request: &mut TransferRequest<Item>,
      item: &Item
    ) {
        let item_id = policy::item<Item>(request);

        assert!(object::id(item) == item_id, EWrongItem);

        let amount = item.amount();

        assert!(amount == 1 || amount == 10 || amount == 100, EWrongAmount);
        policy::add_receipt(Rule {}, request)
    }
}