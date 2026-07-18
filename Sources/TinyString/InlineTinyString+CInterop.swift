// See the note in TinyString+CInterop.swift: intentionally not gated behind
// `#if !hasFeature(Embedded)`.

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
extension InlineTinyString {
    /// Calls `body` with a NUL-terminated C string view of the content. The pointer is only
    /// valid for the duration of `body`.
    ///
    /// Writes the NUL terminator into the type's own unused trailing capacity when there's room
    /// (`length < N`) — no heap allocation. When the buffer is completely full (`length == N`),
    /// the last content byte is dropped to make room for the terminator, matching the same
    /// lossy-on-overflow behavior used elsewhere in this type.
    ///
    /// - Precondition: `N > 0`. `InlineTinyString<0>` has no storage to hold a NUL terminator.
    public func withCString<R>(_ body: (UnsafePointer<CChar>) throws -> R) rethrows -> R {
        precondition(N > 0, "InlineTinyString<0> has no storage to hold a NUL terminator")
        var copy = self
        let nulIndex = Swift.min(length, N - 1)
        copy.storage[nulIndex] = 0
        return try copy.storage.span.extracting(0...nulIndex).withUnsafeBufferPointer { buffer in
            try buffer.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buffer.count) { cString in
                try body(cString)
            }
        }
    }

    /// Constructs an `InlineTinyString` from a NUL-terminated C string, lossily replacing
    /// non-ASCII bytes with `?` and truncating past capacity — the same behavior as
    /// `init(_ string: String)`. Scans for the NUL byte itself rather than calling `strlen`, so
    /// this has no dependency on a linked C runtime.
    public init(cString: UnsafePointer<CChar>) {
        var length = 0
        while cString[length] != 0 { length += 1 }
        let buffer = UnsafeBufferPointer(start: cString, count: length)
        self.init(buffer.lazy.map { UInt8(bitPattern: $0) })
    }

    /// Constructs an `InlineTinyString` from a NUL-terminated C string, throwing on any
    /// non-ASCII byte or if the content exceeds capacity — the same behavior as
    /// `init(strict:)`.
    public init(strict cString: UnsafePointer<CChar>) throws(TinyStringError) {
        var length = 0
        while cString[length] != 0 { length += 1 }
        let buffer = UnsafeBufferPointer(start: cString, count: length)
        try self.init(strict: buffer.lazy.map { UInt8(bitPattern: $0) })
    }
}
