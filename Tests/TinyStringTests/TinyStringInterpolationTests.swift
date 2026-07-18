import Testing
@testable import TinyString

@Suite("TinyString interpolation")
struct TinyStringInterpolationTests {
    @Test("literal-only construction")
    func literalOnly() {
        let s: TinyString = "hello"
        #expect(Array(s) == Array("hello".utf8))
    }

    @Test("interpolating a TinyString")
    func interpolateTinyString() {
        let name = TinyString("World")
        let s = TinyString("Hello, \(name)!")
        #expect(Array(s) == Array("Hello, World!".utf8))
    }

    @Test("interpolating an ASCII value")
    func interpolateASCII() {
        let s = TinyString("char: \(ASCII(0x21))")
        #expect(Array(s) == Array("char: !".utf8))
    }

    @Test("interpolating a UInt8")
    func interpolateUInt8() {
        let byte: UInt8 = 0x41
        let s = TinyString("byte: \(byte)")
        #expect(Array(s) == Array("byte: A".utf8))
    }

    @Test("interpolating integers", arguments: [
        (0, "0"), (42, "42"), (-7, "-7"), (Int.max, "\(Int.max)"), (Int.min, "\(Int.min)"),
    ])
    func interpolateIntegers(value: Int, expected: String) {
        let s = TinyString("n=\(value)")
        #expect(Array(s) == Array("n=\(expected)".utf8))
    }

    @Test("interpolating an unsigned integer")
    func interpolateUnsigned() {
        let value: UInt = 255
        let s = TinyString("n=\(value)")
        #expect(Array(s) == Array("n=255".utf8))
    }

    @Test("interpolating a raw byte sequence")
    func interpolateByteSequence() {
        let s = TinyString("bytes: \([UInt8(0x41), 0x42, 0x43])")
        #expect(Array(s) == Array("bytes: ABC".utf8))
    }

    @Test("combined literal and interpolation")
    func combinedLiteralAndInterpolation() {
        let name = "World"
        let s = TinyString("Hello, \(TinyString(name))! Count: \(3)")
        #expect(Array(s) == Array("Hello, World! Count: 3".utf8))
    }

    @Test("non-ASCII characters in a literal segment are replaced")
    func nonASCIIInLiteral() {
        let s: TinyString = "café"
        #expect(s.byte(at: 3) == ASCII.replacementCharacter.rawValue)
    }
}
