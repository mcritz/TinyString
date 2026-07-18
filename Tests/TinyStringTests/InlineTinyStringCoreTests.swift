import Testing
@testable import TinyString

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
@Suite("InlineTinyString core")
struct InlineTinyStringCoreTests {
    @Test("short input fits entirely")
    func shortInputFits() {
        let s = InlineTinyString<8>("hello")
        #expect(s.byteCount == 5)
        #expect(!s.isFull)
    }

    @Test("lossy init truncates at exactly N bytes", arguments: [
        (3, "hell", 3), (4, "hell", 4), (5, "hell", 4),
    ])
    func lossyInitTruncatesAtBoundary(capacity: Int, input: String, expectedCount: Int) {
        switch capacity {
        case 3:
            let s = InlineTinyString<3>(input)
            #expect(s.byteCount == expectedCount)
            #expect(s.isFull)
        case 4:
            let s = InlineTinyString<4>(input)
            #expect(s.byteCount == expectedCount)
            #expect(s.isFull)
        default:
            let s = InlineTinyString<5>(input)
            #expect(s.byteCount == expectedCount)
            #expect(!s.isFull)
        }
    }

    @Test("lossy init replaces invalid bytes with '?'")
    func lossyInitReplacesInvalidBytes() {
        let s = InlineTinyString<4>([0x41, 0xFF])
        #expect(s.byte(at: 0) == 0x41)
        #expect(s.byte(at: 1) == ASCII.replacementCharacter.rawValue)
    }

    @Test("strict init succeeds when input fits and is valid")
    func strictInitSucceeds() throws {
        let s = try InlineTinyString<4>(strict: [0x41, 0x42])
        #expect(s.byteCount == 2)
    }

    @Test("strict init throws capacityExceeded with correct counts")
    func strictInitThrowsCapacityExceeded() {
        #expect(throws: TinyStringError.capacityExceeded(required: 3, capacity: 2)) {
            _ = try InlineTinyString<2>(strict: [0x41, 0x42, 0x43])
        }
    }

    @Test("strict init throws invalidByte before capacityExceeded when the bad byte comes first")
    func strictInitInvalidByteTakesPriority() {
        #expect(throws: TinyStringError.invalidByte(at: 1, value: 0xFF)) {
            _ = try InlineTinyString<4>(strict: [0x41, 0xFF, 0x42])
        }
    }

    @Test("capacity and isFull")
    func capacityAndIsFull() {
        #expect(InlineTinyString<16>.capacity == 16)
        var s = InlineTinyString<2>()
        #expect(!s.isFull)
        let appendedA = s.append(0x41)
        #expect(appendedA)
        let appendedB = s.append(0x42)
        #expect(appendedB)
        #expect(s.isFull)
        let appendedC = s.append(0x43)
        #expect(!appendedC)
        #expect(s.byteCount == 2)
    }

    @Test("+ concatenates within capacity, truncating lossily on overflow")
    func concatenationOperator() {
        let combined = InlineTinyString<8>("foo") + InlineTinyString<8>("bar")
        #expect(combined.byteCount == 6)

        let overflowed = InlineTinyString<4>("foo") + InlineTinyString<4>("bar")
        #expect(overflowed.byteCount == 4)
        #expect(overflowed.isFull)
    }

    @Test("Equatable and Hashable compare only the live bytes, ignoring unused capacity")
    func equatableHashable() {
        #expect(InlineTinyString<8>("abc") == InlineTinyString<8>("abc"))
        #expect(InlineTinyString<8>("abc") != InlineTinyString<8>("abd"))
        #expect(Set([InlineTinyString<8>("abc"), InlineTinyString<8>("abc"), InlineTinyString<8>("xyz")]).count == 2)
    }

    @Test("withUnsafeBufferPointer exposes exactly the live bytes, not unused capacity")
    func withUnsafeBufferPointerExposesLiveBytes() {
        let s = InlineTinyString<8>("abc")
        let copy = s.withUnsafeBufferPointer { Array($0) }
        #expect(copy == [0x61, 0x62, 0x63])

        let empty = InlineTinyString<8>()
        empty.withUnsafeBufferPointer { #expect($0.count == 0) }
    }

    @Test("withSpan exposes exactly the live bytes, not unused capacity")
    func withSpanExposesLiveBytes() {
        let s = InlineTinyString<8>("abc")
        s.withSpan { span in
            #expect(span.count == 3)
            #expect(span[0] == 0x61)
            #expect(span[1] == 0x62)
            #expect(span[2] == 0x63)
        }

        let empty = InlineTinyString<8>()
        empty.withSpan { #expect($0.count == 0) }
    }
}
