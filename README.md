# TinyString
An ASCII-only text type for [Embedded Swift](https://www.swift.org/documentation/articles/embedded-swift.html) — like `String`, but without the Unicode data tables that Embedded Swift can't afford. The same source runs unmodified on Embedded Swift (including bare-metal RISC-V microcontrollers), [Swift for WebAssembly](https://www.swift.org/install/macos/#swift-sdk-bundles), and standard Swift on Apple/Linux platforms.
## Quick start
```swift
import TinyString

let name = TinyString("World")
let greeting = TinyString("Hello, \(name)! Ultimate Answer: \(42)")
```

Construction is lossy by default — non-ASCII bytes are replaced with `?`, and this path never throws or traps, so string interpolation is always safe to write. When you need a hard guarantee instead of silent replacement, use the strict, typed-throws initializer:

```swift
do {
    let strict = try TinyString(strict: "must be pure ASCII")
} catch let TinyStringError.invalidByte(at: index, value: byte) {
    // handle the specific offending byte
}
```

## Two storage types

| Type | Storage | Use when |
|---|---|---|
| `TinyString` | Heap-backed, copy-on-write, grows freely | Default choice — works on any allocating target (most microcontrollers, Wasm, all standard platforms) |
| `InlineTinyString<N>` | Fixed `N`-byte capacity, stored inline, zero heap allocation | Strict no-`malloc` bare-metal targets |

```swift
var label = InlineTinyString<16>("sensor-01")
label.append(UInt8(ascii: "!")) // truncates/replaces lossily; use init(strict:) for a hard guarantee
```

`InlineTinyString` is backed by `InlineArray`, which requires macOS/iOS/tvOS/watchOS/visionOS "26"-generation OSes on standard, non-Embedded builds. That floor does not apply under Embedded Swift or WebAssembly builds, since Embedded's stdlib isn't tied to a dynamically-linked, OS-versioned runtime.

Both types share the same construction, comparison, and search behavior through `ASCIIByteCollection` — a protocol used only via generics and direct conformance, never as an existential, so it stays Embedded-safe.

## Working with the bytes

Both types are `Collection` (`Element == UInt8`), `Equatable`, and `Hashable`:

```swift
let s = TinyString("hello world")
s.count                          // 11
s[0]                              // 0x68 ('h')
for byte in s { /* ... */ }

s.hasPrefix(TinyString("hello"))  // true
s.hasSuffix(TinyString("world"))  // true
s.contains(TinyString("lo wo"))   // true

TinyString("12345").isAllDigits   // true
```

`hasPrefix`/`hasSuffix`/`contains` are generic over `ASCIIByteCollection`, so they work across both types interchangeably — you can check an `InlineTinyString<8>` prefix against a heap-backed `TinyString`, or vice versa.

For contiguous byte access from pure Swift, both types expose `withSpan`, giving you a bounds-checked, lifetime-scoped [`Span`](https://www.swift.org/documentation/articles/safely-managing-pointers.html) instead of a raw pointer:

```swift
tinyString.withSpan { span in
    span.count
    span[0]
}
```

For interop with APIs that need an actual raw pointer and count (C function boundaries, logging, etc.), both types also expose `withUnsafeBufferPointer`:

```swift
tinyString.withUnsafeBufferPointer { buffer in
    some_c_function(buffer.baseAddress, Int32(buffer.count))
}
```

Prefer `withSpan` unless you're specifically crossing into an unsafe or C API — `Span` gives the same contiguous access with compiler-enforced bounds and lifetime safety instead of relying on the closure-scoping convention alone to keep the pointer from escaping.

## `ASCII`

A single-byte value type with classification helpers (`isDigit`, `isLetter`, `isUppercase`, `isLowercase`, `isAlphanumeric`, `isWhitespace`, `isControl`, `isPrintable`) used internally by both string types and available directly.

## Platform bridging

On non-Embedded builds, both types conform to `CustomStringConvertible` for easy interop with Swift's `String`. This bridging is compiled out under Embedded Swift via `#if !hasFeature(Embedded)` — a deliberate code-size/API-hygiene choice for the smallest bare-metal targets, not a compiler necessity (`String.utf8` and `String(decoding:as:)` themselves work fine under Embedded). `LosslessStringConvertible` is intentionally not adopted — its failable `init?(_:)` would collide with the unconditional, lossy `init(_ string: String)`; use `init(strict:)` when you need a hard ASCII guarantee from a `String`.

## Adding TinyString to your project

For a normal SwiftPM package, add it as a dependency (by path, until it has a published URL):

```swift
dependencies: [
    .package(path: "../TinyString")
]
```

For projects that compile Swift directly through another build system with no SwiftPM in the loop (e.g. ESP-IDF's CMake integration), vendor the source files you need directly — `TinyString` has no dependencies of its own, so copying files works cleanly. This is how it's used today on real ESP32-C3/C6 hardware: only the fixed-capacity `InlineTinyString` half is vendored there, since that project deliberately avoids heap allocation.

## Building and verifying

```sh
# Standard dev loop (macOS/Linux)
swift build && swift test

# Embedded compile + run check, macOS host (separate --build-path avoids clobbering the
# normal build's module cache, since both target the same arm64-apple-macosx triple)
swift build --product TinyStringEmbeddedSmokeTest --build-path .build-embedded \
    -Xswiftc -enable-experimental-feature -Xswiftc Embedded
.build-embedded/arm64-apple-macosx/debug/TinyStringEmbeddedSmokeTest

# Embedded + WebAssembly
swift build --product TinyStringEmbeddedSmokeTest --swift-sdk swift-6.2.3-RELEASE_wasm-embedded

# Plain (non-Embedded) WebAssembly portability check
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

Install the Wasm SDKs once via `swift sdk install <bundle-url>` (see the [Embedded Swift + WebAssembly getting-started guide](https://www.swift.org/documentation/articles/wasm-getting-started.html)); resolve the exact installed identifier with `swift sdk list` rather than hardcoding a version.

**Never** pass the Embedded flag to a whole-package `swift build`/`swift test` — it pulls the Testing framework's dependency graph into Embedded mode and fails. Always scope it with `--product TinyStringEmbeddedSmokeTest`.

`TinyStringEmbeddedSmokeTest` has no test framework dependency (Swift Testing itself can't run under Embedded) — it's a small executable that exercises the full public API with trapping assertions, so a nonzero exit code means something actually broke, not just that it failed to compile.

`swift test` requires a full Xcode installation selected (`xcode-select -s /Applications/Xcode.app`), not just the Command Line Tools — otherwise `import Testing` fails with unrelated `_DarwinFoundation1` errors.

## What this is not
- No regex/pattern matching beyond `hasPrefix`/`hasSuffix`/`contains`.
- No locale-aware anything — it's ASCII-only by definition.
- No Unicode normalization or case-folding.
- No `Codable` conformance.
- No Foundation dependency, ever.

## License

MIT — see [LICENSE](LICENSE).
