# MetalExample

A small SwiftUI app that demonstrates three different ways to use Apple's
Metal framework, one per tab:

| Tab          | Technique                                                             |
| ------------ | --------------------------------------------------------------------- |
| **Triangle** | Raw `MTKView` + custom render pipeline (vertex + fragment shaders)    |
| **Shaders**  | SwiftUI `.colorEffect` with `[[stitchable]]` Metal fragment functions |
| **Filter**   | Metal compute kernels run against a sample image                      |

Targets **iOS 26** with Swift 6.2 and modern Swift concurrency.

## Source layout

```
MetalExample/
├── MetalExampleApp.swift
├── ContentView.swift
├── Shared/
│   ├── MetalContext.swift           # Device, command queue, default library
│   └── ColorResolution.swift        # Color → SIMD4<Float>
├── Features/
│   ├── Triangle/                    # Raw render pipeline demo
│   ├── ShaderGallery/               # SwiftUI shader-modifier gallery
│   └── ImageFilter/                 # Compute-kernel image filters
└── (tests live in MetalExampleTests/)
```

## Building

Open `MetalExample.xcodeproj` in Xcode and run the `MetalExample` scheme on
an iOS 26 simulator (or device). The project uses Xcode's synchronized
folders, so any file you add under `MetalExample/` or `MetalExampleTests/`
is automatically picked up — no drag-and-drop required.

From the command line:

```
xcodebuild -project MetalExample.xcodeproj \
           -scheme MetalExample \
           -destination 'generic/platform=iOS Simulator' \
           build
```

> The `.metal` files in each feature folder are picked up automatically by
> Xcode's default Metal build rule and compiled into the default library
> that `MetalContext` loads at launch.

## Tests

Unit tests use **Swift Testing**. Run with **Cmd-U** in Xcode.
