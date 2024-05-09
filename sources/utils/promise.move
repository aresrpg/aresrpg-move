module aresrpg::promise {

  // ╔════════════════ [ Types ] ════════════════════════════════════════════ ]

  public struct Promise<T> {
    value: T
  }

  // ╔════════════════ [ Package ] ═

  public(package) fun await<T: drop>(value: T): Promise<T> {
    Promise {
      value
    }
  }

  public(package) fun resolve<T: drop>(self: Promise<T>) {
    let Promise<T> { value: _ } = self;
  }

  // ╔════════════════ [ Public ] ═

  public fun value<T: drop>(self: &Promise<T>): &T {
    &self.value
  }
}