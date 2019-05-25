//
extension String {
  ///
  /// Returns a copy of this String with the first letter of each word
  /// uppercased, and all other letters lowercased.
  ///
  func initCapped() -> String {
    var copy = ""

    var nextCharShouldBeUpper = true

    for character in self {
      if nextCharShouldBeUpper, character.isLetter {
        copy += character.uppercased()
      } else {
        copy += character.lowercased()
      }

      if character.isWhitespace || character.isNewline {
        nextCharShouldBeUpper = true
      } else {
        nextCharShouldBeUpper = false
      }
    }
    return copy
  }
}

print(0.byteSwapped)
let myConst = "THis iS a coNSt!" + ":-dddddddd)jj"
print(myConst.initCapped())

for i in 0..<100000 {
  print(i)
}
