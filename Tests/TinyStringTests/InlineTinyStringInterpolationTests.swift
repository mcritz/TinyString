import Testing
@testable import TinyString

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
@Suite("InlineTinyString interpolation")
struct InlineTinyStringInterpolationTests {
    @Test("literal-only construction")
    func literalOnly() {
        let s: InlineTinyString<8> = "hello"
        #expect(s.byteCount == 5)
        #expect(s.byte(at: 0) == 0x68)
    }

    @Test("interpolating another InlineTinyString and an Int")
    func interpolateValues() {
        let name = InlineTinyString<8>("there")
        let s: InlineTinyString<16> = "Hi, \(name)! \(3)"
        #expect(s.byteCount == 12)
        #expect(s.byte(at: 0) == 0x48) // 'H'
    }

    @Test("interpolation overflowing capacity truncates silently")
    func interpolationOverflowTruncates() {
        let s: InlineTinyString<4> = "Hello, \(42)"
        #expect(s.byteCount == 4)
        #expect(s.isFull)
    }
}
