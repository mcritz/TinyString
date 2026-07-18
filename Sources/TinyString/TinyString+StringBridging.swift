// Bridging to Swift's `String` is gated behind `!hasFeature(Embedded)` as a deliberate
// code-size/API-hygiene choice for the smallest bare-metal targets — `String.utf8` and
// `String(decoding:as:)` themselves compile fine under Embedded Swift, so this gate is not a
// compiler necessity. It keeps `String`-shaped surface out of the embedded-facing API.
//
// Note: `LosslessStringConvertible` is intentionally not adopted here. Its `init?(_:)`
// requirement has the same parameter signature as the unconditional, lossy `init(_ string:
// String)` declared in TinyString.swift, and Swift does not allow a failable and non-failable
// initializer to coexist with identical signatures. The strict, validating counterpart is
// `init(strict:) throws(TinyStringError)`, available unconditionally (not just on
// non-Embedded platforms).
#if !hasFeature(Embedded)
extension TinyString: CustomStringConvertible {
    public var description: String {
        String(decoding: storage, as: UTF8.self)
    }
}

extension String {
    public init(_ tinyString: TinyString) {
        self.init(tinyString.description)
    }
}
#endif
