#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
extension InlineTinyString: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self.init()
        value.withUTF8Buffer { buffer in
            for byte in buffer {
                guard length < N else { break }
                storage[length] = byte < 128 ? byte : ASCII.replacementCharacter.rawValue
                length += 1
            }
        }
    }
}

/// The interpolation builder behind `InlineTinyString<N>("Hello, \(name)")`. Mirrors
/// ``TinyStringInterpolation``, but appends directly into fixed inline storage and silently
/// stops once capacity `N` is reached rather than growing.
#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
public struct InlineTinyStringInterpolation<let N: Int>: StringInterpolationProtocol {
    var result = InlineTinyString<N>()

    public init(literalCapacity: Int, interpolationCount: Int) {}

    public mutating func appendLiteral(_ literal: StaticString) {
        literal.withUTF8Buffer { buffer in
            for byte in buffer {
                _ = result.append(byte)
            }
        }
    }

    public mutating func appendInterpolation(_ value: InlineTinyString<N>) {
        for i in 0..<value.length {
            _ = result.append(value.storage[i])
        }
    }

    public mutating func appendInterpolation(_ value: TinyString) {
        for byte in value {
            _ = result.append(byte)
        }
    }

    public mutating func appendInterpolation(_ value: ASCII) {
        _ = result.append(value.rawValue)
    }

    public mutating func appendInterpolation(_ value: UInt8) {
        _ = result.append(value)
    }

    public mutating func appendInterpolation<Value: BinaryInteger>(_ value: Value) {
        let zero: UInt8 = 0x30
        if value == 0 {
            _ = result.append(zero)
            return
        }

        let isNegative = value < 0
        var magnitude = value.magnitude
        var digits = ContiguousArray<UInt8>()
        while magnitude > 0 {
            let digit = UInt8(magnitude % 10)
            digits.append(zero + digit)
            magnitude /= 10
        }

        if isNegative {
            _ = result.append(0x2D) // '-'
        }
        for digit in digits.reversed() {
            _ = result.append(digit)
        }
    }

    public mutating func appendInterpolation(_ sequence: some Sequence<UInt8>) {
        for byte in sequence {
            _ = result.append(byte)
        }
    }
}

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
extension InlineTinyString: ExpressibleByStringInterpolation {
    public init(stringInterpolation: InlineTinyStringInterpolation<N>) {
        self = stringInterpolation.result
    }
}
