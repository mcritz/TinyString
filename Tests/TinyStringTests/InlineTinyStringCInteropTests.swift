import Testing
@testable import TinyString

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
@Suite("InlineTinyString C interop")
struct InlineTinyStringCInteropTests {
    @Test("withCString writes the NUL into unused trailing capacity when there's room")
    func withCStringRoomToSpare() {
        let s = InlineTinyString<8>("Mo")
        s.withCString { cStr in
            #expect(cStr[0] == 0x4D)
            #expect(cStr[1] == 0x6F)
            #expect(cStr[2] == 0)
        }
    }

    @Test("withCString truncates the last byte when the buffer is completely full")
    func withCStringFullBuffer() {
        let s = InlineTinyString<3>("ABC")
        s.withCString { cStr in
            #expect(cStr[0] == 0x41)
            #expect(cStr[1] == 0x42)
            #expect(cStr[2] == 0)
        }
    }

    @Test("init(cString:) round-trips ASCII content")
    func initFromCStringRoundTrips() {
        let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
        literal.withUnsafeBufferPointer { buf in
            let s = InlineTinyString<8>(cString: buf.baseAddress!)
            #expect(s == InlineTinyString<8>("Hi"))
        }
    }

    @Test("init(cString:) replaces invalid bytes with '?'")
    func initFromCStringReplacesInvalidBytes() {
        let invalid: [CChar] = [0x48, -1, 0] // 'H', then an invalid (non-ASCII) byte
        invalid.withUnsafeBufferPointer { buf in
            let s = InlineTinyString<8>(cString: buf.baseAddress!)
            #expect(s.byte(at: 1) == ASCII.replacementCharacter.rawValue)
        }
    }

    @Test("init(strict cString:) succeeds on valid ASCII")
    func initStrictFromCStringSucceeds() throws {
        let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
        let s = try literal.withUnsafeBufferPointer { buf in
            try InlineTinyString<8>(strict: buf.baseAddress!)
        }
        #expect(s == InlineTinyString<8>("Hi"))
    }

    @Test("init(strict cString:) throws invalidByte at the correct index")
    func initStrictFromCStringThrows() {
        let invalid: [CChar] = [0x48, -1, 0] // 'H', then an invalid (non-ASCII) byte
        #expect(throws: TinyStringError.invalidByte(at: 1, value: 0xFF)) {
            _ = try invalid.withUnsafeBufferPointer { buf in
                try InlineTinyString<8>(strict: buf.baseAddress!)
            }
        }
    }
}
