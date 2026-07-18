/// Errors thrown by the strict (`init(strict:)`) construction paths.
///
/// Deliberately a concrete `Error`-conforming `enum`, used exclusively with typed throws
/// (`throws(TinyStringError)`) rather than plain `throws`, which boxes `any Error` — a pattern
/// Embedded Swift supports but that TinyString avoids in its core to keep the existential-free.
public enum TinyStringError: Error, Equatable, Sendable {
    /// A byte at `index` was not valid ASCII (>= 0x80).
    case invalidByte(at: Int, value: UInt8)
    /// The input required more bytes than an `InlineTinyString<N>`'s fixed capacity allows.
    case capacityExceeded(required: Int, capacity: Int)
}
