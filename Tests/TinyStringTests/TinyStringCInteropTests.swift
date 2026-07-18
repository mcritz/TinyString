import Testing
@testable import TinyString

@Suite("TinyString C interop")
struct TinyStringCInteropTests {
    @Test("withCString produces a NUL-terminated view of the content")
    func withCStringProducesNulTerminatedView() {
        let s = TinyString("Mo")
        s.withCString { cStr in
            #expect(cStr[0] == 0x4D)
            #expect(cStr[1] == 0x6F)
            #expect(cStr[2] == 0)
        }
    }

    @Test("init(cString:) round-trips ASCII content")
    func initFromCStringRoundTrips() {
        let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
        literal.withUnsafeBufferPointer { buf in
            let s = TinyString(cString: buf.baseAddress!)
            #expect(s == TinyString("Hi"))
        }
    }

    @Test("init(cString:) replaces invalid bytes with '?'")
    func initFromCStringReplacesInvalidBytes() {
        let invalid: [CChar] = [0x48, -1, 0] // 'H', then an invalid (non-ASCII) byte
        invalid.withUnsafeBufferPointer { buf in
            let s = TinyString(cString: buf.baseAddress!)
            #expect(s.byte(at: 1) == ASCII.replacementCharacter.rawValue)
        }
    }

    @Test("init(strict cString:) succeeds on valid ASCII")
    func initStrictFromCStringSucceeds() throws {
        let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
        let s = try literal.withUnsafeBufferPointer { buf in
            try TinyString(strict: buf.baseAddress!)
        }
        #expect(s == TinyString("Hi"))
    }

    @Test("init(strict cString:) throws invalidByte at the correct index")
    func initStrictFromCStringThrows() {
        let invalid: [CChar] = [0x48, -1, 0] // 'H', then an invalid (non-ASCII) byte
        #expect(throws: TinyStringError.invalidByte(at: 1, value: 0xFF)) {
            _ = try invalid.withUnsafeBufferPointer { buf in
                try TinyString(strict: buf.baseAddress!)
            }
        }
    }
}
