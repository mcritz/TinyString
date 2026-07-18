/// A fixed-capacity, zero-heap-allocation ASCII string, stored inline.
///
/// `InlineTinyString<N>` is the strict no-malloc counterpart to ``TinyString``: `N` bytes of
/// storage live directly inside the value (backed by `InlineArray<N, UInt8>`), so no heap
/// allocation ever occurs. Use it on bare-metal targets where `malloc` isn't available or
/// wanted; use ``TinyString`` everywhere else.
///
/// Like ``TinyString``, construction is lossy by default: input longer than `N` bytes is
/// silently truncated and invalid (non-ASCII) bytes are replaced with `?` — the ergonomic
/// construction path never traps. `init(strict:)` reports both conditions via
/// `throws(TinyStringError)` instead.
///
/// `InlineArray` requires macOS/iOS/tvOS/watchOS/visionOS "26"-generation OSes on standard,
/// non-Embedded builds (a stdlib availability floor, not a TinyString restriction). Under
/// Embedded Swift this floor does not apply, since the embedded stdlib isn't tied to a
/// dynamically-linked, OS-versioned runtime — so the `@available` gate below is itself
/// conditional on `!hasFeature(Embedded)`.
#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
public struct InlineTinyString<let N: Int>: ASCIIByteCollection, Equatable, Hashable, Sendable {
    var storage: InlineArray<N, UInt8>
    var length: Int

    public static var capacity: Int { N }
    public var isFull: Bool { length == N }

    public init() {
        storage = InlineArray(repeating: 0)
        length = 0
    }

    public init(_ bytes: some Sequence<UInt8>) {
        self.init()
        for byte in bytes {
            guard length < N else { break }
            storage[length] = byte < 128 ? byte : ASCII.replacementCharacter.rawValue
            length += 1
        }
    }

    public init(_ string: String) {
        self.init(string.utf8)
    }

    public init(strict bytes: some Sequence<UInt8>) throws(TinyStringError) {
        self.init()
        var iterator = bytes.makeIterator()
        var index = 0
        while let byte = iterator.next() {
            guard byte < 128 else { throw .invalidByte(at: index, value: byte) }
            guard length < N else {
                var required = index + 1
                while iterator.next() != nil { required += 1 }
                throw .capacityExceeded(required: required, capacity: N)
            }
            storage[length] = byte
            length += 1
            index += 1
        }
    }

    public init(strict string: String) throws(TinyStringError) {
        try self.init(strict: Array(string.utf8))
    }

    public var byteCount: Int { length }

    public func byte(at index: Int) -> UInt8 {
        storage[index]
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        for i in 0..<rhs.length {
            guard result.length < N else { break }
            result.storage[result.length] = rhs.storage[i]
            result.length += 1
        }
        return result
    }

    @discardableResult
    public mutating func append(_ byte: UInt8) -> Bool {
        guard length < N else { return false }
        storage[length] = byte < 128 ? byte : ASCII.replacementCharacter.rawValue
        length += 1
        return true
    }

    // `InlineArray` does not itself conform to Equatable/Hashable, so synthesis is unavailable;
    // these compare/hash only the live `length` bytes, ignoring unused trailing capacity.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.length == rhs.length else { return false }
        for i in 0..<lhs.length where lhs.storage[i] != rhs.storage[i] {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(length)
        for i in 0..<length {
            hasher.combine(storage[i])
        }
    }

    /// Direct read-only access to the live bytes (not the unused trailing capacity), for
    /// interop with APIs that need a raw pointer and count (e.g. C function boundaries). The
    /// pointer is only valid for the duration of `body`.
    ///
    /// Prefer ``withSpan(_:)`` unless you specifically need a raw pointer for an unsafe or C
    /// API — `Span` gives the same contiguous access with compiler-enforced bounds and lifetime
    /// safety instead of relying on the closure-scoping convention alone.
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
        try withSpan { span in try span.withUnsafeBufferPointer(body) }
    }

    /// Safe, bounds-checked, lifetime-scoped access to the live bytes (not the unused trailing
    /// capacity). Prefer this over ``withUnsafeBufferPointer(_:)`` for any pure-Swift caller;
    /// reach for the unsafe variant only at an actual C/unsafe API boundary.
    public func withSpan<R>(_ body: (Span<UInt8>) throws -> R) rethrows -> R {
        try body(storage.span.extracting(0..<length))
    }
}
