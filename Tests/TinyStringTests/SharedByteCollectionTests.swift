import Testing
@testable import TinyString

@Suite("ASCIIByteCollection shared behavior")
struct SharedByteCollectionTests {
    @Test("hasPrefix/hasSuffix/contains on TinyString")
    func tinyStringSearch() {
        let s = TinyString("hello world")
        #expect(s.hasPrefix(TinyString("hello")))
        #expect(!s.hasPrefix(TinyString("world")))
        #expect(s.hasSuffix(TinyString("world")))
        #expect(!s.hasSuffix(TinyString("hello")))
        #expect(s.contains(TinyString("lo wo")))
        #expect(!s.contains(TinyString("xyz")))
        #expect(s.contains(TinyString("")))
    }

    @Test("hasPrefix/hasSuffix/contains work across the two concrete types")
    func crossTypeSearch() throws {
        guard #available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *) else {
            return
        }
        let s = TinyString("hello world")
        let prefix = InlineTinyString<8>("hello")
        #expect(s.hasPrefix(prefix))

        let inline = InlineTinyString<16>("hello world")
        #expect(inline.hasSuffix(TinyString("world")))
    }

    @Test("isAllDigits / isAllLetters / isAllPrintable")
    func classification() {
        #expect(TinyString("12345").isAllDigits)
        #expect(!TinyString("123a5").isAllDigits)
        #expect(TinyString("hello").isAllLetters)
        #expect(!TinyString("hello!").isAllLetters)
        #expect(TinyString("hello!").isAllPrintable)
        #expect(!TinyString("hi\u{01}").isAllPrintable)
    }
}
