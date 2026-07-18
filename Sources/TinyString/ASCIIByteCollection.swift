/// Shared behavior for TinyString's concrete storage types.
///
/// Used only via direct static conformance (`struct TinyString: ASCIIByteCollection`) and
/// generic constraints (`func f<S: ASCIIByteCollection>(_ s: S)`) — never as `any
/// ASCIIByteCollection`. Embedded Swift disallows existentials, so this protocol exists purely
/// to let `TinyString` and `InlineTinyString<N>` share `Collection` conformance and search/
/// classification logic without runtime type metadata.
public protocol ASCIIByteCollection: Collection where Element == UInt8, Index == Int {
    var byteCount: Int { get }
    func byte(at index: Int) -> UInt8
}

extension ASCIIByteCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { byteCount }

    public func index(after i: Int) -> Int {
        i + 1
    }

    public subscript(position: Int) -> UInt8 {
        byte(at: position)
    }

    public var count: Int { byteCount }
    public var isEmpty: Bool { byteCount == 0 }

    public var isAllDigits: Bool {
        allSatisfy { ASCII($0).isDigit }
    }

    public var isAllLetters: Bool {
        allSatisfy { ASCII($0).isLetter }
    }

    public var isAllPrintable: Bool {
        allSatisfy { ASCII($0).isPrintable }
    }

    public func hasPrefix<Other: ASCIIByteCollection>(_ other: Other) -> Bool {
        guard other.byteCount <= byteCount else { return false }
        for i in 0..<other.byteCount where byte(at: i) != other.byte(at: i) {
            return false
        }
        return true
    }

    public func hasSuffix<Other: ASCIIByteCollection>(_ other: Other) -> Bool {
        guard other.byteCount <= byteCount else { return false }
        let offset = byteCount - other.byteCount
        for i in 0..<other.byteCount where byte(at: offset + i) != other.byte(at: i) {
            return false
        }
        return true
    }

    public func contains<Other: ASCIIByteCollection>(_ other: Other) -> Bool {
        guard other.byteCount > 0 else { return true }
        guard other.byteCount <= byteCount else { return false }
        var start = 0
        while start <= byteCount - other.byteCount {
            var matched = true
            for i in 0..<other.byteCount where byte(at: start + i) != other.byte(at: i) {
                matched = false
                break
            }
            if matched { return true }
            start += 1
        }
        return false
    }
}
