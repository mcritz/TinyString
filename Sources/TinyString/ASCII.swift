/// A single ASCII byte (0x00–0x7F), with classification helpers.
public struct ASCII: RawRepresentable, Equatable, Hashable, Comparable, Sendable {
    public var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public init(_ byte: UInt8) {
        self.rawValue = byte
    }

    public var isDigit: Bool {
        rawValue >= 0x30 && rawValue <= 0x39
    }

    public var isUppercase: Bool {
        rawValue >= 0x41 && rawValue <= 0x5A
    }

    public var isLowercase: Bool {
        rawValue >= 0x61 && rawValue <= 0x7A
    }

    public var isLetter: Bool {
        isUppercase || isLowercase
    }

    public var isAlphanumeric: Bool {
        isLetter || isDigit
    }

    public var isWhitespace: Bool {
        switch rawValue {
        case 0x20, 0x09, 0x0A, 0x0B, 0x0C, 0x0D:
            return true
        default:
            return false
        }
    }

    public var isControl: Bool {
        rawValue <= 0x1F || rawValue == 0x7F
    }

    public var isPrintable: Bool {
        rawValue >= 0x20 && rawValue <= 0x7E
    }

    /// The `?` byte used to stand in for invalid (non-ASCII) input on lossy construction paths.
    public static let replacementCharacter = ASCII(0x3F)

    public static func < (lhs: ASCII, rhs: ASCII) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
