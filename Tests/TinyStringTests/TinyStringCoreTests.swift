import Testing
@testable import TinyString

@Suite("TinyString core")
struct TinyStringCoreTests {
    
    @Test("lossy init replaces invalid bytes with '?' at the correct offset")
    func lossyInitReplacesInvalidBytes() {
        let s = TinyString([0x41, 0x42, 0xFF, 0x43])
        #expect(s.byteCount == 4)
        #expect(s.byte(at: 0) == 0x41)
        #expect(s.byte(at: 1) == 0x42)
        #expect(s.byte(at: 2) == ASCII.replacementCharacter.rawValue)
        #expect(s.byte(at: 3) == 0x43)
    }

    @Test("lossy init from String never throws")
    func lossyInitFromString() {
        let s = TinyString("café")
        #expect(s.byteCount == 5) // é has two code points e and ´
        #expect(s.byte(at: 3) == ASCII.replacementCharacter.rawValue)
    }

    @Test("strict init succeeds on valid ASCII")
    func strictInitSucceeds() throws {
        let s = try TinyString(strict: [0x41, 0x42, 0x43])
        #expect(s.byteCount == 3)
    }

    @Test("strict init throws invalidByte at the correct index")
    func strictInitThrows() {
        #expect(throws: TinyStringError.invalidByte(at: 1, value: 0xFF)) {
            _ = try TinyString(strict: [0x41, 0xFF, 0x42])
        }
    }

    @Test("count and isEmpty")
    func countAndIsEmpty() {
        #expect(TinyString().isEmpty)
        #expect(TinyString().count == 0)
        #expect(TinyString("abc").count == 3)
        #expect(!TinyString("abc").isEmpty)
    }

    @Test("Collection subscript access")
    func collectionSubscript() {
        let s = TinyString("abc")
        #expect(s[0] == 0x61)
        #expect(s[1] == 0x62)
        #expect(s[2] == 0x63)
        #expect(Array(s) == [0x61, 0x62, 0x63])
    }

    @Test("+ concatenates")
    func concatenationOperator() {
        let s = TinyString("foo") + TinyString("bar")
        #expect(s.byteCount == 6)
        #expect(Array(s) == Array("foobar".utf8))
    }

    @Test("+= concatenates in place")
    func concatenationAssignment() {
        var s = TinyString("foo")
        s += TinyString("bar")
        #expect(s.byteCount == 6)
    }

    @Test("append(_:UInt8) replaces invalid bytes")
    func appendByte() {
        var s = TinyString("ab")
        s.append(UInt8(0x63))
        s.append(UInt8(0xFF))
        #expect(s.byteCount == 4)
        #expect(s.byte(at: 3) == ASCII.replacementCharacter.rawValue)
    }

    @Test("append(_:TinyString) grows the buffer")
    func appendTinyString() {
        var s = TinyString("ab")
        s.append(TinyString("cd"))
        #expect(s.byteCount == 4)
    }

    @Test("value semantics: mutating a copy leaves the original untouched")
    func copyOnWriteValueSemantics() {
        let original = TinyString("value")
        var copy = original
        copy.append(UInt8(0x21))
        #expect(original.byteCount == 5)
        #expect(copy.byteCount == 6)
    }

    @Test("Equatable and Hashable")
    func equatableHashable() {
        #expect(TinyString("abc") == TinyString("abc"))
        #expect(TinyString("abc") != TinyString("abd"))
        #expect(Set([TinyString("abc"), TinyString("abc"), TinyString("xyz")]).count == 2)
    }

    @Test("withUnsafeBufferPointer exposes exactly the live bytes")
    func withUnsafeBufferPointerExposesLiveBytes() {
        let s = TinyString("abc")
        let copy = s.withUnsafeBufferPointer { Array($0) }
        #expect(copy == Array("abc".utf8))

        let empty = TinyString()
        empty.withUnsafeBufferPointer { #expect($0.count == 0) }
    }

    @Test("withSpan exposes exactly the live bytes")
    func withSpanExposesLiveBytes() {
        let s = TinyString("abc")
        s.withSpan { span in
            #expect(span.count == 3)
            #expect(span[0] == 0x61)
            #expect(span[1] == 0x62)
            #expect(span[2] == 0x63)
        }

        let empty = TinyString()
        empty.withSpan { #expect($0.count == 0) }
    }
}
