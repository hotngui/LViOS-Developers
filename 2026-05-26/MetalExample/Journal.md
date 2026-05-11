# Journal.md — The Story of MetalExample

## The Big Picture

Imagine you've got a friend who's heard "Metal is fast" a thousand times but
has never actually written a single line of it. They want to peek under the
hood without committing to building a game engine. **MetalExample is the
guided tour for that friend.**

It's a three-tab SwiftUI app. Each tab is one self-contained way to use
Metal:

- Tab 1 says, "Here is a triangle. Here is exactly how the GPU drew it."
- Tab 2 says, "Here is a colorful animated thing. SwiftUI did most of the
  plumbing — you just wrote the math."
- Tab 3 says, "Here is an image. Now watch a thousand GPU threads grayscale
  it in parallel."

Three tabs, three escalating ways the GPU shows up in your life.

## Architecture Deep Dive

Think of the app like a **kitchen with three line cooks** who all share one
oven and one stack of pans. The oven is the GPU itself. The stack of pans is
the `MTLCommandQueue`. The orders are command buffers.

`MetalContext` is the head chef. Created once at app launch, it owns:

- The **`MTLDevice`** — the GPU itself, the oven.
- The **`MTLCommandQueue`** — the stack of pans, queued in order.
- The **`MTLLibrary`** — the recipe book, compiled from every `.metal`
  file in the project at build time.

Each tab is a line cook with a different job:

- **Triangle's renderer** is the most traditional cook. They use the
  classic Metal pipeline: vertex stage → rasterizer → fragment stage. They
  upload a tiny `Uniforms` struct (rotation + 3 colors), tell the GPU
  "draw 3 vertices," and the GPU does the rest.
- **Shader Gallery** is the express line. SwiftUI provides `.colorEffect`,
  which says "for every pixel of this view, run *my* fragment function."
  The cook only writes the fragment function — no pipeline, no command
  buffer, no encoder. SwiftUI handles all of that.
- **Image Filter** uses **compute kernels** instead of rasterized
  rendering. There are no triangles, no vertex stage. Instead, a grid of
  GPU threads each grabs one pixel of the input, mangles it, and writes
  the result. It's the GPU as a parallel `for` loop.

All three cooks share the head chef's oven, queue, and recipe book.

## The Codebase Map

```
MetalExample/
├── MetalExampleApp.swift     # Entry point. Creates MetalContext, injects it.
├── ContentView.swift         # The TabView.
│
├── Shared/
│   ├── MetalContext.swift    # The head chef. Owns device, queue, library.
│   └── ColorResolution.swift # Tiny helper: SwiftUI Color → SIMD4<Float>.
│
└── Features/
    ├── Triangle/
    │   ├── TriangleView.swift          # The screen
    │   ├── TriangleControls.swift      # Sliders + color pickers
    │   ├── TriangleMetalView.swift     # UIViewRepresentable wrapping MTKView
    │   ├── TriangleRenderer.swift      # MTKViewDelegate (the actual draw call)
    │   ├── TriangleViewModel.swift     # @Observable state
    │   ├── TriangleUniforms.swift      # Swift mirror of the Metal Uniforms struct
    │   └── Triangle.metal              # vertex_main + fragment_main
    │
    ├── ShaderGallery/
    │   ├── ShaderGalleryView.swift     # Paged TabView of demos
    │   ├── ShaderDemo.swift            # Model: id + title + summary
    │   ├── ShaderDemoView.swift        # One demo (title, description, canvas)
    │   ├── ShaderCanvas.swift          # Rectangle + .visualEffect + Shader
    │   └── Shaders.metal               # plasma / ripple / valueNoise (stitchable)
    │
    └── ImageFilter/
        ├── ImageFilterView.swift        # The screen
        ├── ImageFilterViewModel.swift   # Selected filter, blur radius, output
        ├── FilterKind.swift             # enum: original/grayscale/boxBlur/sobel
        ├── ComputeFilterEngine.swift    # Builds pipelines, dispatches kernels
        ├── SampleImageProvider.swift    # Procedural test image via ImageRenderer
        └── Filters.metal                # 3 compute kernels
```

If you want to learn Metal in this app, **read in this order:**
`MetalContext.swift` → `Triangle.metal` → `TriangleRenderer.swift` →
`Shaders.metal` → `ShaderCanvas.swift` → `Filters.metal` →
`ComputeFilterEngine.swift`.

## Tech Stack & Why

- **SwiftUI** because the whole point of the demo is "look how clean
  Metal can be in a modern Apple app." UIKit would be three times the
  code.
- **`MTKView` (via `UIViewRepresentable`)** for the Triangle tab because
  there is no SwiftUI-native equivalent for "I want to drive my own
  vertex pipeline." `MTKView` gives us the timing loop, the
  `currentDrawable`, and the `currentRenderPassDescriptor` for free.
- **SwiftUI shader modifiers** for the Shader Gallery because they
  *exist*, and dragging in `MTKView` would be silly when SwiftUI can run
  fragment shaders natively. The whole demo is "look how short the code
  is."
- **Compute kernels** for image filtering because they're the natural
  vehicle for "run the same function on every pixel in parallel." Could
  we use a fragment shader to do this? Yes. But compute kernels feel
  more honest about what's happening: a 2D grid of GPU threads doing
  data-parallel work.
- **`ImageRenderer`** to make the sample image at startup, because
  bundling photos in a demo project felt wrong.
- **Swift Testing** (`import Testing`) instead of XCTest, per the global
  Swift style guide.
- **No third-party frameworks.** Everything is Apple-provided.

## The Journey

### "Why does my uniform buffer look corrupt?"
**The bug:** First pass at `TriangleUniforms` had `angle` followed by
`SIMD4<Float>` colors. The triangle came out with the wrong colors and
nothing rotated.
**The cause:** Metal's `float4` has 16-byte alignment. A struct that
starts with `float angle` puts the next `float4` at offset 16, *not* at
offset 4. Swift mirrors that automatically (because `SIMD4<Float>` has
16-byte alignment too), but only if you don't manually try to "pack"
the layout. The fix was to trust Swift and not add explicit padding —
the compiler does it for you.
**Lesson:** When a Swift struct mirrors a Metal struct, line up the
field types, not the byte offsets. Swift's default alignment matches
Metal's expectations as long as you use SIMD types.

### "Why is `Color.resolve(in:)` returning weird values?"
The `Color → SIMD4<Float>` extension takes an `EnvironmentValues`. If
you pass `EnvironmentValues()` (a default-constructed instance), system
colors that depend on dynamic environment (like `.accent` or
`.primary`) won't resolve correctly. We dodge this by capturing the
real environment in the `UIViewRepresentable` with
`@Environment(\.self)`. That gives us the full chain of environment
values that the SwiftUI hierarchy sees.
**Lesson:** `@Environment(\.self)` is the escape hatch when you need
the whole `EnvironmentValues` bag rather than a specific key.

### "Why is `valueNoise` solid pink?"
First version of the noise shader used a closure `auto hash = [](float2 p)
{ ... };` inside the kernel. Modern Metal supports a lot of C++ but
nested function objects compile inconsistently across hardware. Rewrote
the helper as a top-level `static inline float hash21(...)` and the
shader started rendering correctly.
**Lesson:** When in doubt, prefer plain helper functions in `.metal`
files over lambdas — they're the most widely supported across Metal
versions and devices.

### "Why does my filter output look magenta?"
The compute kernels write to `.rgba8Unorm`. The `MTKTextureLoader`
default for the *input* is whatever matches the source `CGImage`,
which on iOS is often `.bgra8Unorm`. The Metal `read()` call returns
`half4` regardless, so the shader code stays pretty, but if you read
the output bytes back assuming BGRA when they're RGBA — magenta. The
fix in `ComputeFilterEngine.makeUIImage` is to always assume RGBA and
use `CGImageAlphaInfo.premultipliedLast`.
**Lesson:** Pixel formats are a footgun. Pick one for output, write it
down, and convert at the boundaries.

## Engineer's Wisdom

- **Trust the type system at struct boundaries.** Don't manually pack
  uniforms. Swift's `SIMD` types and the Metal compiler agree on
  alignment by default — just match the field order and types.
- **One `MTLDevice` per app.** Always. Threading them through your code
  via `.environment` (SwiftUI) or DI is much saner than re-creating one
  every time you need to render.
- **Compile your `.metal` files once at app launch** by using
  `device.makeDefaultLibrary()` and looking up functions by name. Don't
  call `device.makeLibrary(source:)` on every frame.
- **Build pipeline states once and reuse them.** They are expensive to
  create; cheap to use.
- **Block GPU work like grown-ups.** For tiny demos
  `commandBuffer.commit() + waitUntilCompleted()` is fine. For real
  work, use `addCompletedHandler` and bridge to async/await.
- **Keep view models out of the GPU path.** A view model owns SwiftUI
  state. The renderer owns Metal state. The view in between translates.
  This keeps the renderer from accidentally retaining SwiftUI types.

## If I Were Starting Over...

- I'd put the `MTLLibrary` lookups in a typed wrapper instead of
  string-based name lookups. Right now if you typo `"triangle_vertex"`
  in `TriangleRenderer.swift`, you find out at runtime.
- I'd make `ComputeFilterEngine.apply` async from day one. The
  blocking version is fine for the demo, but the migration to async is
  a small annoyance to do later.
- I'd add a "save filtered image to Photos" action on the Filter tab.
  It's the obvious next thing a user wants once they see the result.
- I'd consider a fourth tab showing **MPSGraph** or **Core Image with
  custom Metal kernels**, just to round out the "ways Metal shows up"
  story. (Out of scope for now — but a fine extension.)
