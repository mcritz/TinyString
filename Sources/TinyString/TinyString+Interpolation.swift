extension TinyString: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        var result = ContiguousArray<UInt8>()
        value.withUTF8Buffer { buffer in
            result.reserveCapacity(buffer.count)
            for byte in buffer {
                result.append(byte < 128 ? byte : ASCII.replacementCharacter.rawValue)
            }
        }
        storage = result
    }
}

/// The interpolation builder behind `TinyString("Hello, \(name)")`. Literal segments and every
/// interpolated value are appended as raw ASCII bytes — no `String` formatting machinery is
/// used, so this stays Embedded-safe.
public struct TinyStringInterpolation: StringInterpolationProtocol {
    var bytes = ContiguousArray<UInt8>()

    public init(literalCapacity: Int, interpolationCount: Int) {
        bytes.reserveCapacity(literalCapacity + interpolationCount * 4)
    }

    public mutating func appendLiteral(_ literal: StaticString) {
        literal.withUTF8Buffer { buffer in
            for byte in buffer {
                bytes.append(byte < 128 ? byte : ASCII.replacementCharacter.rawValue)
            }
        }
    }

    public mutating func appendInterpolation(_ value: TinyString) {
        bytes.append(contentsOf: value.storage)
    }

    public mutating func appendInterpolation(_ value: ASCII) {
        bytes.append(value.rawValue < 128 ? value.rawValue : ASCII.replacementCharacter.rawValue)
    }

    public mutating func appendInterpolation(_ value: UInt8) {
        bytes.append(value < 128 ? value : ASCII.replacementCharacter.rawValue)
    }

    public mutating func appendInterpolation<Value: BinaryInteger>(_ value: Value) {
        appendDigits(of: value)
    }

    public mutating func appendInterpolation(_ sequence: some Sequence<UInt8>) {
        for byte in sequence {
            bytes.append(byte < 128 ? byte : ASCII.replacementCharacter.rawValue)
        }
    }

    /// Formats an integer as ASCII decimal digits by hand, without going through `String(_:)`.
    private mutating func appendDigits<Value: BinaryInteger>(of value: Value) {
        let zero: UInt8 = 0x30
        if value == 0 {
            bytes.append(zero)
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
            bytes.append(0x2D) // '-'
        }
        bytes.append(contentsOf: digits.reversed())
    }
}

extension TinyString: ExpressibleByStringInterpolation {
    public init(stringInterpolation: TinyStringInterpolation) {
        storage = stringInterpolation.bytes
    }
}
