import Testing
@testable import TinyString

@Suite("Integer parsing")
struct IntegerParsingTests {
    @Test("parses a valid unsigned decimal")
    func validUnsigned() {
        #expect(UInt8(TinyString("42")) == 42)
    }

    @Test("rejects a value that overflows the target type")
    func overflow() {
        #expect(UInt8(TinyString("999")) == nil)
    }

    @Test("rejects a '-' sign on an unsigned type")
    func negativeOnUnsigned() {
        #expect(UInt8(TinyString("-1")) == nil)
    }

    @Test("rejects empty input")
    func empty() {
        #expect(UInt8(TinyString("")) == nil)
    }

    @Test("rejects a non-digit byte")
    func nonDigit() {
        #expect(UInt8(TinyString("4a")) == nil)
    }

    @Test("parses a negative signed decimal")
    func validSignedNegative() {
        #expect(Int(TinyString("-42")) == -42)
    }

    @Test("correctly parses Self.min via downward accumulation")
    func selfMin() {
        #expect(Int8(TinyString("-128")) == Int8.min)
    }

    @Test("rejects overflow past Self.min")
    func overflowPastMin() {
        #expect(Int8(TinyString("-129")) == nil)
    }

    @Test("rejects a bare sign with no digits")
    func bareSign() {
        #expect(Int(TinyString("-")) == nil)
    }

    @Test("works identically across both storage types")
    func acrossStorageTypes() {
        guard #available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *) else { return }
        #expect(Int(InlineTinyString<8>("123")) == 123)
    }
}
