// Unlike TinyString+StringBridging.swift, this is intentionally NOT gated behind
// `#if !hasFeature(Embedded)`. C interop is core to why `withUnsafeBufferPointer` already
// exists unconditionally — it matters most on the embedded targets these helpers exist for, not
// least on them.

extension TinyString {
    /// Calls `body` with a NUL-terminated C string view of the content. The pointer is only
    /// valid for the duration of `body`.
    public func withCString<R>(_ body: (UnsafePointer<CChar>) throws -> R) rethrows -> R {
        var bytes = storage
        bytes.append(0)
        return try bytes.withUnsafeBufferPointer { buffer in
            try buffer.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buffer.count) { cString in
                try body(cString)
            }
        }
    }

    /// Constructs a `TinyString` from a NUL-terminated C string, lossily replacing non-ASCII
    /// bytes with `?` — the same behavior as `init(_ string: String)`. Scans for the NUL byte
    /// itself rather than calling `strlen`, so this has no dependency on a linked C runtime.
    public init(cString: UnsafePointer<CChar>) {
        var length = 0
        while cString[length] != 0 { length += 1 }
        let buffer = UnsafeBufferPointer(start: cString, count: length)
        self.init(buffer.lazy.map { UInt8(bitPattern: $0) })
    }

    /// Constructs a `TinyString` from a NUL-terminated C string, throwing if any byte is not
    /// valid ASCII — the same behavior as `init(strict:)`.
    public init(strict cString: UnsafePointer<CChar>) throws(TinyStringError) {
        var length = 0
        while cString[length] != 0 { length += 1 }
        let buffer = UnsafeBufferPointer(start: cString, count: length)
        try self.init(strict: buffer.lazy.map { UInt8(bitPattern: $0) })
    }
}
