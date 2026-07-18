import Testing
@testable import TinyString

#if !hasFeature(Embedded)
@Suite("TinyString String bridging")
struct TinyStringStringBridgingTests {
    @Test("description round-trips ASCII-only content")
    func descriptionRoundTrips() {
        let s = TinyString("bridged content")
        #expect(s.description == "bridged content")
    }

    @Test("lossy init(_:String) replaces non-ASCII content")
    func lossyInitFromStringReplaces() {
        let s = TinyString("©åƒẽ")
        #expect(s.description.contains("?"))
    }
}
#endif
