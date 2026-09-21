# Image Cache Exerciser

## Overview

An iOS demo app (bundle display name "AS Cache") for exercising and measuring image caching
strategies. It loads a configurable number of real-estate photos through SwiftUI's native
`AsyncImage(request:)` (iOS 27) backed by a dedicated `URLCache`, lets you switch between
request modes (HTTP Rules / Cache First / Reload / Cache Only — i.e. `URLRequest.CachePolicy`
values), preload or clear the cache, and dump live statistics (memory footprint, URLCache
memory/disk usage and capacity). Built for the LV iOS Developers meetup series.

## Architecture

Pure SwiftUI — no storyboards, no UIKit view controllers, no App/Scene delegates, no
third-party dependencies.

- `ImageCacheExerciserApp.swift` — `@main` App struct. Creates the single `AppSettings`
  instance and injects it into the environment.
- `Stuff/AppSettings.swift` — `@MainActor @Observable` settings model (photo count, image
  size, request mode). Persists to `UserDefaults` under the keys `photoCount`, `imageSize`,
  `requestMode`. Also exposes `imagePaths` (the URL list for the current settings). Legacy
  keys from earlier incarnations (`toolkit`, `cacheType`) are actively removed on launch.
- `Cache/` — the caching core:
  - `ImageNetworking.swift` — static `URLCache` (64 MB memory / 100 MB disk, dedicated
    directory) and the `URLSession` configured with it.
  - `ImageRequestMode.swift` — the four request modes, each mapping to a
    `URLRequest.CachePolicy`, with picker titles and explanation strings.
  - `AsyncImageCacheController.swift` — `@Observable` wrapper over the `URLCache` for
    clearing and formatted disk-usage reporting.
- `Stuff/Cache.swift` — `@MainActor` facade (`Cache.default`) over the `Cache/` pieces:
  `clear()` (via the controller), `preload(with:)` (task group fetching through
  `ImageNetworking.imageSession` so responses land in the shared `URLCache`), and
  `dumpStats(...)` returning key/value rows (app memory via Mach `task_vm_info`, URLCache
  memory/disk usage and capacities).
- `Stuff/ImageProvider.swift` — hardcoded list of Zillow photo URL stems; builds medium or
  high-resolution URLs.
- `Screens/Main/MainView.swift` — settings screen: slider + segmented pickers (request mode
  picker shows the selected mode's explanation below it), cache action buttons, progress
  overlay during async cache work, `fullScreenCover` to the viewer and `sheet` to the stats.
- `Screens/Photo Viewer SwiftUI/` — `PhotoViewer` (List of `PhotoView` rows, with
  `.asyncImageURLSession(ImageNetworking.imageSession)` applied so every image loads through
  the app's own URLCache) and `PhotoView` (`AsyncImage(request:)` with the current request
  mode's cache policy, 0.15 s fade via the `transaction:` overload, placeholder image for the
  empty and failure phases, 4:3 aspect box).
- `Screens/Stats/StatsView.swift` — two-column `LazyVGrid` dump of the stats rows.

## Conventions & Gotchas

- The Xcode project uses a filesystem-synchronized root group (objectVersion 110): adding or
  deleting files under `Image Cache Exerciser/` needs **no pbxproj edits**. Only `Info.plist`
  is a membership exception.
- **Never edit `project.pbxproj` directly while Xcode is open** — use the xcode-tools MCP
  commands (e.g. `UpdateTargetBuildSetting`) or ask the user to make the change in Xcode.
- `Info.plist` is an empty dict; launch screen is generated
  (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`). There is no scene manifest — SwiftUI App
  lifecycle only.
- Deployment target is **iOS 27.0** (explicit, target-level) — required for
  `AsyncImage(request:)` and `.asyncImageURLSession(_:)`, which are un-gated in the code.
- Changing the Request Mode does **not** clear or reconfigure anything — it only changes the
  `cachePolicy` on each image's `URLRequest`. (The old Kingfisher version cleared and
  reconfigured the cache when the cache type changed; that concept is gone.)
- "Cache Only" mode legitimately shows placeholder images for anything not already cached —
  that's the demo working, not a bug.
- `URLCache` only persists responses the server marks cacheable under `.useProtocolCachePolicy`;
  photos.zillowstatic.com sends long-lived cache headers, so all four modes behave visibly
  differently as intended.

## Build & Run

Open `Image Cache Exerciser.xcodeproj`, scheme "Image Cache Exerciser", run on an iOS 27+
simulator or device. No test targets. Photos load from photos.zillowstatic.com, so previews
and runs need network access.
