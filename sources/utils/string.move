module aresrpg::string {

  use std::{
    string::{String, to_ascii, from_ascii},
    ascii
  };

  // ╔════════════════ [ Public ] ════════════════════════════════════════════ ]

  public fun to_lower_case(str: String): String {
    let string = to_ascii(str);
    let (mut bytes, mut i) = (ascii::into_bytes(string), 0);

    while (i < bytes.length()) {
      let byte = vector::borrow_mut(&mut bytes, i);
      if (*byte >= 65u8 && *byte <= 90u8) *byte = *byte + 32u8;
      i = i + 1;
    };

    from_ascii(ascii::string(bytes))
  }

  public fun contains_whitespace(str: String): bool {
    let string = to_ascii(str);
    let (mut bytes, mut i) = (ascii::into_bytes(string), 0);

    while (i < bytes.length()) {
      let byte = vector::borrow_mut(&mut bytes, i);
      if (*byte == 32u8) return true;
      i = i + 1;
    };

    false
  }
}