# TinyString

An ASCII-only text type for [Embedded Swift](https://www.swift.org/documentation/articles/embedded-swift.html) — like `String`, but without the Unicode data tables that Embedded Swift can't afford. The same source runs unmodified on Embedded Swift, Swift for WebAssembly, and standard Swift on Apple/Linux platforms.

## Quick start

```swift
import TinyString

let name = TinyString("World")
let greeting = TinyString("Hello, \(name)! Count: \(42)")
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

## `ASCII`

A single-byte value type with classification helpers (`isDigit`, `isLetter`, `isUppercase`, `isLowercase`, `isAlphanumeric`, `isWhitespace`, `isControl`, `isPrintable`) used internally by both string types and available directly.

## Platform bridging

On non-Embedded builds, both types conform to `CustomStringConvertible` for easy interop with Swift's `String`. This bridging is compiled out under Embedded Swift via `#if !hasFeature(Embedded)` — a deliberate code-size/API-hygiene choice for the smallest bare-metal targets, not a compiler necessity (`String.utf8` and `String(decoding:as:)` themselves work fine under Embedded).

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
