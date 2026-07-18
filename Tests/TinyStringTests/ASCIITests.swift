import Testing
@testable import TinyString

@Suite("ASCII classification")
struct ASCIITests {
    @Test("digit boundaries", arguments: [
        (UInt8(0x2F), false), (UInt8(0x30), true), (UInt8(0x39), true), (UInt8(0x3A), false),
    ])
    func digitBoundaries(byte: UInt8, expected: Bool) {
        #expect(ASCII(byte).isDigit == expected)
    }

    @Test("uppercase boundaries", arguments: [
        (UInt8(0x40), false), (UInt8(0x41), true), (UInt8(0x5A), true), (UInt8(0x5B), false),
    ])
    func uppercaseBoundaries(byte: UInt8, expected: Bool) {
        #expect(ASCII(byte).isUppercase == expected)
    }

    @Test("lowercase boundaries", arguments: [
        (UInt8(0x60), false), (UInt8(0x61), true), (UInt8(0x7A), true), (UInt8(0x7B), false),
    ])
    func lowercaseBoundaries(byte: UInt8, expected: Bool) {
        #expect(ASCII(byte).isLowercase == expected)
    }

    @Test("letter combines upper and lower")
    func letter() {
        #expect(ASCII(0x41).isLetter)
        #expect(ASCII(0x7A).isLetter)
        #expect(!ASCII(0x30).isLetter)
    }

    @Test("alphanumeric combines letter and digit")
    func alphanumeric() {
        #expect(ASCII(0x30).isAlphanumeric)
        #expect(ASCII(0x41).isAlphanumeric)
        #expect(!ASCII(0x20).isAlphanumeric)
    }

    @Test("whitespace bytes", arguments: [
        UInt8(0x20), UInt8(0x09), UInt8(0x0A), UInt8(0x0B), UInt8(0x0C), UInt8(0x0D),
    ])
    func whitespace(byte: UInt8) {
        #expect(ASCII(byte).isWhitespace)
    }

    @Test("control boundaries", arguments: [
        (UInt8(0x00), true), (UInt8(0x1F), true), (UInt8(0x20), false), (UInt8(0x7E), false), (UInt8(0x7F), true),
    ])
    func controlBoundaries(byte: UInt8, expected: Bool) {
        #expect(ASCII(byte).isControl == expected)
    }

    @Test("printable boundaries", arguments: [
        (UInt8(0x1F), false), (UInt8(0x20), true), (UInt8(0x7E), true), (UInt8(0x7F), false),
    ])
    func printableBoundaries(byte: UInt8, expected: Bool) {
        #expect(ASCII(byte).isPrintable == expected)
    }

    @Test("Equatable and Hashable")
    func equatableHashable() {
        #expect(ASCII(65) == ASCII(65))
        #expect(ASCII(65) != ASCII(66))
        #expect(Set([ASCII(65), ASCII(65), ASCII(66)]).count == 2)
    }

    @Test("Comparable")
    func comparable() {
        #expect(ASCII(10) < ASCII(20))
        #expect(!(ASCII(20) < ASCII(10)))
    }

    @Test("replacementCharacter is '?'")
    func replacementCharacter() {
        #expect(ASCII.replacementCharacter.rawValue == 0x3F)
    }
}
