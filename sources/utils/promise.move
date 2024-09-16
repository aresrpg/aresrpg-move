module aresrpg::promise {

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Promise<T> {
    value: T
  }

  // ╔════════════════ [ Constants ] ═

  const EWrongValue: u64 = 101;

  // ╔════════════════ [ Package ] ═

  public(package) fun await<T: drop>(value: T): Promise<T> {
    Promise {
      value
    }
  }

  public(package) fun resolve<T: drop>(self: Promise<T>, verify: T) {
    let Promise<T> { value } = self;
    assert!(value == verify, EWrongValue);
  }

  // ╔════════════════ [ Public ] ═

  public fun value<T: drop>(self: &Promise<T>): &T {
    &self.value
  }
}