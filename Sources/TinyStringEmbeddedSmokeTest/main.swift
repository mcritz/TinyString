import TinyString

// Exercises TinyString's full public API with trapping assertions (no test framework — this
// target has no dependency on Swift Testing so it can be built under Embedded Swift). Build and
// run it via the commands documented in the README to confirm the library actually behaves
// correctly under Embedded Swift and WebAssembly, not just that it compiles.

func check(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func checkASCII() {
    check(ASCII(0x30).isDigit, "'0' should be a digit")
    check(!ASCII(0x41).isDigit, "'A' should not be a digit")
    check(ASCII(0x41).isUppercase, "'A' should be uppercase")
    check(ASCII(0x61).isLowercase, "'a' should be lowercase")
    check(ASCII(0x41).isLetter, "'A' should be a letter")
    check(ASCII(0x30).isAlphanumeric, "'0' should be alphanumeric")
    check(ASCII(0x20).isWhitespace, "space should be whitespace")
    check(ASCII(0x00).isControl, "NUL should be a control byte")
    check(ASCII(0x41).isPrintable, "'A' should be printable")
    check(ASCII(10) < ASCII(20), "ASCII should be Comparable")
}

func checkTinyStringCore() {
    let lossy = TinyString([0x41, 0x42, 0xFF, 0x43])
    check(lossy.byteCount == 4, "lossy init should keep all 4 bytes")
    check(lossy.byte(at: 2) == ASCII.replacementCharacter.rawValue, "invalid byte should become '?'")

    do {
        _ = try TinyString(strict: [0x41, 0x42, 0x43])
    } catch {
        check(false, "strict init should not throw on valid ASCII")
    }

    do {
        _ = try TinyString(strict: [0x41, 0xFF])
        check(false, "strict init should throw on invalid byte")
    } catch let TinyStringError.invalidByte(at: index, value: value) {
        check(index == 1 && value == 0xFF, "strict init should report the correct invalid byte")
    } catch {
        check(false, "unexpected error type")
    }

    var mutable = TinyString("AB")
    mutable.append(TinyString("CD"))
    check(mutable.byteCount == 4, "append(_:TinyString) should grow the buffer")
    mutable.append(UInt8(0x45))
    check(mutable.byteCount == 5, "append(_:UInt8) should grow the buffer")

    let combined = TinyString("foo") + TinyString("bar")
    check(combined.byteCount == 6, "+ should concatenate")

    combined.withUnsafeBufferPointer { buffer in
        check(buffer.count == 6, "withUnsafeBufferPointer should expose exactly byteCount bytes")
        check(buffer[0] == 0x66, "withUnsafeBufferPointer should see the correct bytes")
    }

    combined.withSpan { span in
        check(span.count == 6, "withSpan should expose exactly byteCount bytes")
        check(span[0] == 0x66, "withSpan should see the correct bytes")
    }

    check(combined.hasPrefix(TinyString("foo")), "hasPrefix should match")
    check(combined.hasSuffix(TinyString("bar")), "hasSuffix should match")
    check(combined.contains(TinyString("oob")), "contains should find a substring")
    check(!combined.contains(TinyString("xyz")), "contains should reject a non-substring")

    let original = TinyString("value")
    var copy = original
    copy.append(UInt8(0x21))
    check(original.byteCount == 5, "TinyString should have copy-on-write value semantics")
}

func checkTinyStringInterpolation() {
    let name = TinyString("World")
    let count = 42
    let greeting = TinyString("Hello, \(name)! Count: \(count), byte: \(ASCII(0x21)), neg: \(-7)")
    check(greeting.hasPrefix(TinyString("Hello, World! Count: 42")), "interpolation should format values as ASCII bytes")
    check(greeting.contains(TinyString("neg: -7")), "interpolation should format negative integers")
}

func checkTinyStringCInterop() {
    let name = TinyString("Mo")
    name.withCString { cStr in
        check(cStr[0] == 0x4D, "withCString should start with the first content byte")
        check(cStr[1] == 0x6F, "withCString should have the second content byte")
        check(cStr[2] == 0, "withCString should be NUL-terminated right after the content")
    }

    let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
    literal.withUnsafeBufferPointer { buf in
        let roundTrip = TinyString(cString: buf.baseAddress!)
        check(roundTrip == TinyString("Hi"), "init(cString:) should round-trip ASCII content")
    }

    // Array.withUnsafeBufferPointer's closure parameter is untyped `throws`, so calling a
    // throws(TinyStringError)-typed initializer inside it directly would force boxing into
    // `any Error`, which Embedded Swift disallows. Route through a concrete Result instead.
    let strictResult: Result<TinyString, TinyStringError> = literal.withUnsafeBufferPointer { buf in
        do throws(TinyStringError) {
            return .success(try TinyString(strict: buf.baseAddress!))
        } catch {
            return .failure(error)
        }
    }
    switch strictResult {
    case .success(let value):
        check(value == TinyString("Hi"), "init(strict cString:) should succeed on valid ASCII")
    case .failure:
        check(false, "init(strict cString:) should not throw on valid ASCII")
    }

    let invalid: [CChar] = [0x48, -1, 0] // 'H', then an invalid (non-ASCII) byte
    invalid.withUnsafeBufferPointer { buf in
        let lossy = TinyString(cString: buf.baseAddress!)
        check(lossy.byte(at: 1) == ASCII.replacementCharacter.rawValue, "init(cString:) should replace invalid bytes with '?'")
    }
    let invalidResult: Result<TinyString, TinyStringError> = invalid.withUnsafeBufferPointer { buf in
        do throws(TinyStringError) {
            return .success(try TinyString(strict: buf.baseAddress!))
        } catch {
            return .failure(error)
        }
    }
    switch invalidResult {
    case .success:
        check(false, "init(strict cString:) should throw on an invalid byte")
    case .failure(.invalidByte(at: let index, value: let value)):
        check(index == 1 && value == 0xFF, "init(strict cString:) should report the correct invalid byte")
    case .failure:
        check(false, "unexpected error case")
    }
}

#if !hasFeature(Embedded)
func checkTinyStringBridging() {
    let s = TinyString("bridged")
    check(s.description == "bridged", "description should round-trip ASCII content")
}
#endif

#if !hasFeature(Embedded)
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
#endif
func checkInlineTinyString() {
    var s = InlineTinyString<8>("hello")
    check(s.byteCount == 5, "InlineTinyString should hold short input in full")
    check(!s.isFull, "5 bytes in an 8-byte capacity should not be full")

    let truncated = InlineTinyString<4>("hello")
    check(truncated.byteCount == 4, "lossy init should truncate to capacity")
    check(truncated.isFull, "truncated result should report full")

    let lossyInvalid = InlineTinyString<4>([0x41, 0xFF])
    check(lossyInvalid.byte(at: 1) == ASCII.replacementCharacter.rawValue, "invalid byte should become '?'")

    do {
        _ = try InlineTinyString<4>(strict: [0x41, 0x42])
    } catch {
        check(false, "strict init should not throw when input fits and is valid")
    }

    do {
        _ = try InlineTinyString<2>(strict: [0x41, 0x42, 0x43])
        check(false, "strict init should throw on capacity overflow")
    } catch let TinyStringError.capacityExceeded(required: required, capacity: capacity) {
        check(required == 3 && capacity == 2, "capacityExceeded should report the right counts")
    } catch {
        check(false, "unexpected error type")
    }

    do {
        _ = try InlineTinyString<4>(strict: [0x41, 0xFF, 0x42])
        check(false, "strict init should throw invalidByte before capacityExceeded when a bad byte comes first")
    } catch let TinyStringError.invalidByte(at: index, value: value) {
        check(index == 1 && value == 0xFF, "invalidByte should be reported before capacity is even relevant")
    } catch {
        check(false, "unexpected error type")
    }

    check(s.append(UInt8(0x21)), "append should succeed while under capacity")
    check(s.byteCount == 6, "append should grow length")

    let combined = InlineTinyString<8>("foo") + InlineTinyString<8>("bar")
    check(combined.byteCount == 6, "+ should concatenate within capacity")

    combined.withSpan { span in
        check(span.count == 6, "withSpan should expose exactly the live bytes, not unused capacity")
        check(span[0] == 0x66, "withSpan should see the correct bytes")
    }

    combined.withUnsafeBufferPointer { buffer in
        check(buffer.count == 6, "withUnsafeBufferPointer should expose exactly the live bytes, not unused capacity")
        check(buffer[0] == 0x66, "withUnsafeBufferPointer should see the correct bytes")
    }

    let interpolated: InlineTinyString<16> = "Hi, \(InlineTinyString<8>("there"))! \(3)"
    check(interpolated.hasPrefix(InlineTinyString<16>("Hi, there! 3")), "InlineTinyString interpolation should work")

    check(s == InlineTinyString<8>("hello!"), "InlineTinyString should be Equatable")

    // withCString: room to spare (length < N) writes NUL into unused trailing capacity.
    let roomy = InlineTinyString<8>("Mo")
    roomy.withCString { cStr in
        check(cStr[0] == 0x4D && cStr[1] == 0x6F, "withCString should expose the content bytes")
        check(cStr[2] == 0, "withCString should be NUL-terminated right after the content")
    }

    // withCString: completely full (length == N) truncates the last byte to fit the NUL.
    let full = InlineTinyString<3>("ABC")
    full.withCString { cStr in
        check(cStr[0] == 0x41 && cStr[1] == 0x42, "withCString on a full buffer should keep all but the last byte")
        check(cStr[2] == 0, "withCString on a full buffer should still be NUL-terminated")
    }

    let literal: [CChar] = [0x48, 0x69, 0] // "Hi\0"
    literal.withUnsafeBufferPointer { buf in
        let roundTrip = InlineTinyString<8>(cString: buf.baseAddress!)
        check(roundTrip == InlineTinyString<8>("Hi"), "InlineTinyString.init(cString:) should round-trip ASCII content")
    }

    let strictResult: Result<InlineTinyString<8>, TinyStringError> = literal.withUnsafeBufferPointer { buf in
        do throws(TinyStringError) {
            return .success(try InlineTinyString<8>(strict: buf.baseAddress!))
        } catch {
            return .failure(error)
        }
    }
    switch strictResult {
    case .success(let value):
        check(value == InlineTinyString<8>("Hi"), "InlineTinyString.init(strict cString:) should succeed on valid ASCII")
    case .failure:
        check(false, "InlineTinyString.init(strict cString:) should not throw on valid ASCII")
    }
}

checkASCII()
checkTinyStringCore()
checkTinyStringInterpolation()
checkTinyStringCInterop()
#if !hasFeature(Embedded)
checkTinyStringBridging()
#endif
// Under Embedded, InlineTinyString carries no @available restriction (see its declaration),
// and `if #available` itself needs a Darwin runtime symbol that Embedded doesn't link — so call
// directly there and only guard with `if #available` on normal, non-Embedded builds.
#if hasFeature(Embedded)
checkInlineTinyString()
#else
if #available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *) {
    checkInlineTinyString()
}
#endif
