# CLAUDE.md — MetalExample

## Project overview
A SwiftUI demo app that shows three different ways of using Apple's Metal
framework, organized as three tabs:
1. **Triangle** — a hand-rolled render pipeline drawing a colored triangle.
2. **Shaders** — SwiftUI's `.colorEffect` modifier driving `[[stitchable]]`
   Metal fragment functions, animated by `TimelineView`.
3. **Filter** — Metal compute kernels (grayscale / box blur / Sobel edge
   detect) applied to a procedurally generated sample image.

The app is intentionally a learning/demo project: every Metal-touching
file should be readable end-to-end without prior context.

## Architecture decisions

- **Single `MetalContext`** (`Shared/MetalContext.swift`) holds the
  `MTLDevice`, `MTLCommandQueue`, and default `MTLLibrary`. It's
  `@Observable @MainActor` and injected via `.environment(...)`.
- **Folder-by-feature.** Each tab has its own folder under `Features/`,
  with one type per file.
- **One `.metal` file per feature** rather than a single shared shader
  file. This keeps each example self-contained and matches the folder
  layout.
- **All view models are `@Observable @MainActor`** per the global Swift
  style guide.
- Per the global SwiftUI style guide:
  - Use the `Tab` API (not `tabItem`)
  - `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`
  - `foregroundStyle()` instead of `foregroundColor()`
  - `View` subviews (no view-as-computed-property)

## Build / run

- **Target:** iOS 26.0+
- **Swift:** 6.2 with strict concurrency
- **Setup:** see `README.md` — the `.xcodeproj` is not committed; create
  one in Xcode and let synchronized folders pick up the source.

## Quirks / gotchas

- **`TriangleUniforms` layout matches Metal's `Uniforms` struct exactly.**
  Swift adds 12 bytes of padding after the `Float angle` field because
  `SIMD4<Float>` has 16-byte alignment, which is exactly what Metal
  expects. Don't reorder these fields without checking the Metal struct.
- **`Triangle.metal` colors come as three named `float4`s rather than an
  array** so the Swift `TriangleUniforms` struct stays simple.
- **Compute kernels read 8-bit textures as `half`.** That's intentional —
  Metal handles the conversion and the kernels stay branch-free for any
  8-bit-per-channel input format.
- **`ComputeFilterEngine.apply` blocks on `waitUntilCompleted`.** This is
  fine for the 512x512 demo image but should be reworked into an async
  function with a completion handler if the input ever gets larger.
- **`SampleImageProvider`** generates the input image at startup using
  `ImageRenderer`. We avoid bundling photos so the demo is self-contained.

## Tests

Unit tests live in `MetalExampleTests/` and use **Swift Testing**
(`import Testing`, `@Test`, `#expect`). Tests cover the view models and
the `FilterKind` / `ShaderDemo` enums. The Metal renderers themselves are
not unit-tested — that would require an XCTest UI run on a device.
