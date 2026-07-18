extension FixedWidthInteger {
    /// Parses a decimal integer from an ASCII byte collection (`TinyString` or
    /// `InlineTinyString<N>`), mirroring `Int.init?(_ text: some StringProtocol)`. Returns `nil`
    /// on empty input, any non-digit byte, a `-` sign on an unsigned type, a bare `-` with no
    /// digits, or overflow of `Self`'s range — never traps.
    public init?<Bytes: ASCIIByteCollection>(_ bytes: Bytes) {
        var iterator = bytes.makeIterator()
        guard var byte = iterator.next() else { return nil }

        var isNegative = false
        if byte == 0x2D { // '-'
            guard Self.isSigned else { return nil }
            guard let next = iterator.next() else { return nil }
            isNegative = true
            byte = next
        }

        var value: Self = 0
        while true {
            guard byte >= 0x30, byte <= 0x39 else { return nil }
            let digit = Self(byte - 0x30)
            let (multiplied, overflowedMultiply) = value.multipliedReportingOverflow(by: 10)
            guard !overflowedMultiply else { return nil }
            // Accumulate downward for negative values (via subtraction) rather than negating a
            // built-up positive value at the end - handles Self.min correctly, whose magnitude
            // doesn't fit in Self when positive (e.g. Int8.min == -128, but 128 doesn't fit).
            let (added, overflowedAdd) = isNegative
                ? multiplied.subtractingReportingOverflow(digit)
                : multiplied.addingReportingOverflow(digit)
            guard !overflowedAdd else { return nil }
            value = added

            guard let next = iterator.next() else { break }
            byte = next
        }
        self = value
    }
}
