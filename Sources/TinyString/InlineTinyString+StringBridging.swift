// See the note in TinyString+StringBridging.swift: this gate is a deliberate code-size/API-
// hygiene choice, not a compiler necessity. `LosslessStringConvertible` is intentionally not
// adopted here for the same reason as `TinyString`: its failable `init?(_:)` would collide
// with the unconditional, lossy `init(_ string: String)`.
#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
extension InlineTinyString: CustomStringConvertible {
    public var description: String {
        var bytes = [UInt8]()
        bytes.reserveCapacity(length)
        for i in 0..<length {
            bytes.append(storage[i])
        }
        return String(decoding: bytes, as: UTF8.self)
    }
}

@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
extension String {
    public init<let N: Int>(_ inlineTinyString: InlineTinyString<N>) {
        self.init(inlineTinyString.description)
    }
}
#endif
