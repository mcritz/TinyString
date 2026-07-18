/// A heap-backed, copy-on-write, dynamically-sized ASCII string.
///
/// This is TinyString's default, ergonomic type — analogous to Swift's `String` but restricted
/// to the 128-value ASCII byte range (0x00–0x7F), with no Unicode tables. Backed directly by
/// `ContiguousArray<UInt8>`, which provides copy-on-write value semantics for free and never
/// bridges to `NSArray`.
///
/// Construction is lossy by default (`init(_:)`): invalid bytes (>= 0x80) are replaced with
/// `?` and never trap or throw, so `TinyString("Hello, \(name)")` is always safe to write. Use
/// `init(strict:)` when a hard failure on invalid input is preferable to silent replacement.
public struct TinyString: ASCIIByteCollection, Equatable, Hashable, Sendable {
    var storage: ContiguousArray<UInt8>

    public init() {
        storage = []
    }

    public init(_ bytes: some Sequence<UInt8>) {
        storage = ContiguousArray(bytes.map { $0 < 128 ? $0 : ASCII.replacementCharacter.rawValue })
    }

    public init(_ string: String) {
        self.init(string.utf8)
    }

    public init(strict bytes: some Sequence<UInt8>) throws(TinyStringError) {
        var out = ContiguousArray<UInt8>()
        for (index, byte) in bytes.enumerated() {
            guard byte < 128 else { throw .invalidByte(at: index, value: byte) }
            out.append(byte)
        }
        storage = out
    }

    public init(strict string: String) throws(TinyStringError) {
        try self.init(strict: Array(string.utf8))
    }

    public var byteCount: Int { storage.count }

    public func byte(at index: Int) -> UInt8 {
        storage[index]
    }

    public static func + (lhs: TinyString, rhs: TinyString) -> TinyString {
        var result = lhs
        result.storage.append(contentsOf: rhs.storage)
        return result
    }

    public static func += (lhs: inout TinyString, rhs: TinyString) {
        lhs.storage.append(contentsOf: rhs.storage)
    }

    public mutating func append(_ byte: UInt8) {
        storage.append(byte < 128 ? byte : ASCII.replacementCharacter.rawValue)
    }

    public mutating func append(_ other: TinyString) {
        storage.append(contentsOf: other.storage)
    }

    /// Direct read-only access to the underlying bytes, for interop with APIs that need a raw
    /// pointer and count (e.g. C function boundaries). The pointer is only valid for the
    /// duration of `body`.
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
        try storage.withUnsafeBufferPointer(body)
    }
}
