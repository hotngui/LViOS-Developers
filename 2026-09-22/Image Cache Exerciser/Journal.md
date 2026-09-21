# Journal — Image Cache Exerciser

## The Big Picture

Imagine you're arguing with a friend about image caching strategies over coffee. "Cache-first
is faster!" "Sure, until your listings go stale!" This app settles those arguments with
receipts. It downloads a pile of real-estate photos through SwiftUI's native
`AsyncImage(request:)` (new in iOS 27), lets you flip between request modes (HTTP Rules /
Cache First / Reload / Cache Only — the four flavors of `URLRequest.CachePolicy`), preload or
nuke the cache, and then shows you the actual numbers: app memory footprint, and the backing
`URLCache`'s memory and disk usage against its capacities. It's a lab bench for image caching,
dressed up as a tiny app.

## Architecture Deep Dive

Think of the app as a small restaurant:

- **`AppSettings` is the order ticket.** One `@Observable` object created at launch, pinned
  to the environment, readable by every screen. When you move the slider, the ticket updates
  and quietly carbon-copies itself into `UserDefaults` (via `didSet`) so tomorrow's shift
  remembers your order.
- **`Cache` is now the pantry manager, not the freezer.** The freezer itself is Foundation's
  `URLCache` (64 MB shelf space in memory, 100 MB in the back room on disk — see
  `ImageNetworking`), and `AsyncImage` shops from it natively. The `Cache.default` facade just
  manages it: emptying (`clear()` via `AsyncImageCacheController`), stocking ahead of the
  dinner rush (`preload(with:)` pumps every URL through the *same* `URLSession` the viewer
  uses, so responses land on the same shelves), and auditing (`dumpStats()` reports URLCache
  usage/capacity and asks Mach for the app's physical memory footprint).
- **`ImageRequestMode` is the standing instruction to the kitchen.** Each of its four cases
  is a `URLRequest.CachePolicy` — check the pantry first, always cook fresh, pantry-only, or
  follow the supplier's freshness labels (HTTP cache headers). Changing it doesn't reorganize
  anything; it just changes the instruction stamped on each order.
- **`ImageProvider` is the supplier's catalog.** A hardcoded list of Zillow photo URL stems;
  ask for N items at medium or high resolution and it hands back full URLs.
- **The views are the dining room.** `MainView` (the control panel) presents `PhotoViewer`
  full-screen (the actual cache workout — a List of `KFImage`s) and `StatsView` as a sheet
  (the audit report). No view talks to another view; they all read the same `AppSettings`
  from the environment.

The flow for the main event: slider says 111 photos → `AppSettings.imagePaths` builds 111
URLs → `PhotoViewer` lists them (with `.asyncImageURLSession(ImageNetworking.imageSession)`
routing every `AsyncImage` through the app's own URLCache) → each `PhotoView` builds a
`URLRequest` with the selected cache policy → Dump Stats shows the damage.

## The Codebase Map

```
Image Cache Exerciser/
├── ImageCacheExerciserApp.swift      @main App — creates AppSettings, shows MainView
├── Info.plist                        empty dict (SwiftUI lifecycle, generated launch screen)
├── Stuff/
│   ├── AppSettings.swift             @Observable settings model + UserDefaults persistence
│   ├── Cache.swift                   facade over the Cache/ pieces (clear/preload/stats)
│   └── ImageProvider.swift           the URL catalog
├── Screens/
│   ├── Main/MainView.swift           settings screen + action buttons + progress overlay
│   ├── Photo Viewer SwiftUI/
│   │   ├── PhotoViewer.swift         full-screen List of photos, Close/Dump Stats toolbar,
│   │   │                             .asyncImageURLSession() for the custom cache
│   │   └── PhotoView.swift           one row: AsyncImage(request:) in a 4:3 box + URL caption
│   └── Stats/StatsView.swift         two-column LazyVGrid of stat rows
└── Cache/                            the caching core (promoted from staging in Sept 2026)
    ├── ImageNetworking.swift         the URLCache + URLSession pair
    ├── ImageRequestMode.swift        four URLRequest.CachePolicy flavors + UI strings
    └── AsyncImageCacheController.swift  @Observable clear/disk-usage wrapper
```

## Tech Stack & Why

- **SwiftUI (everything)** — as of Sept 2026 this app is 100% SwiftUI. It started life as a
  UIKit storyboard app with a SwiftUI photo viewer bolted on for A/B comparison; the UIKit
  half earned its retirement (see The Journey). SwiftUI collapsed three different navigation
  mechanisms (storyboard segue + `prepare(for:)`, `@IBSegueAction`, manual `present`) into
  `.fullScreenCover` and `.sheet`.
- **`@Observable` + environment injection** — one settings object, every screen reads it,
  no singletons-reaching-into-view-controllers. Chosen over scattered `@AppStorage` because
  the model owns derived logic (`imagePaths`, clamping, a default that's computed at runtime
  from `ImageProvider.maxCount`) that `@AppStorage` can't express.
- **`AsyncImage(request:)` + `URLCache` (iOS 27)** — the cache under test. Chosen over
  Kingfisher (which this app used until Sept 2026) because iOS 27's SwiftUI finally does
  natively what the third-party libraries existed for: HTTP caching by default, a `URLRequest`
  initializer for per-image cache policy, and `.asyncImageURLSession(_:)` to supply your own
  session and `URLCache`. Zero dependencies; the whole cache is Foundation.
- **Filesystem-synchronized Xcode project** (objectVersion 110) — files on disk *are* the
  target. The entire migration added and deleted a dozen files without one pbxproj merge
  conflict. If you've ever resolved a `project.pbxproj` conflict at 11pm, you understand.

## The Journey

### 2026-09-20 (part three) — The Stat That Lied

"Disk Used" in the stats sheet sat frozen at 82 KB no matter how many photos got cached.
The culprit: `AsyncImageCacheController.diskUsage` was a *cached copy* of
`URLCache.currentDiskUsage`, refreshed only at init and after `clearCache()`. There was even
a `monitorDiskUsage()` loop written for exactly this — but nothing ever called it. So the
sheet faithfully reported the cache's size *as of app launch* (82 KB being URLCache's empty
sqlite bookkeeping), forever. Classic "observable property that nobody re-observes": an
`@Observable` var only notifies when it's *written*, and nothing was writing it.

Fix: made `refreshDiskUsage()` internal and `dumpStats()` calls it before reading, so every
Dump Stats tap gets a fresh number. Lesson: a cached snapshot needs a story for *when it
refreshes*, and "someone will surely call the refresh loop" isn't one — grep for callers
before trusting a monitor method. (Side note: `currentDiskUsage` is URLCache's own
bookkeeping and can lag the filesystem slightly; the "App Used Disk" row walks the same
directory and is the ground truth.)

The `Cache/` staging folder finally got its moment. Replaced Kingfisher wholesale with iOS
27's new `AsyncImage(request:)` API. The story beats:

- **The library became a language feature.** Kingfisher earned its keep for years by doing
  what `AsyncImage` couldn't: caching, custom storage, per-image policy. iOS 27 closed the
  gap — `AsyncImage` now HTTP-caches by default, `init(request:)` takes a `URLRequest` so you
  control `cachePolicy` per image, and `.asyncImageURLSession(_:)` points a whole subtree at
  your own `URLSession`/`URLCache`. The three staged files (`ImageNetworking`,
  `ImageRequestMode`, `AsyncImageCacheController`) slotted in as the cache, the policy picker,
  and the auditor. `KFImage.url(...).fade(...).placeholder {...}` became
  `AsyncImage(request:transaction:)` with a phase closure — the `transaction:` overload
  reproduces the 0.15 s fade for free.
- **The concept map changed, not just the API.** Kingfisher's "cache type" (Default / Memory
  / Disk) was a *storage configuration* — switching it meant clearing and rebuilding the
  cache. `URLRequest.CachePolicy` is a *per-request instruction* — switching it clears
  nothing. So `changeCacheType(to:)` and its `.onChange` handler didn't get ported; they got
  *deleted*. When migrating between frameworks, watch for code that exists only because of the
  old framework's shape.
- **Preload without a prefetcher.** Kingfisher had `ImagePrefetcher`; URLCache has... nothing.
  But it doesn't need anything: a `withTaskGroup` firing `imageSession.data(for:)` with
  `.returnCacheDataElseLoad` populates the cache through the exact session `AsyncImage` reads
  from. The key insight: preload and display must share one `URLSession`, or you're stocking
  a different pantry than the one the kitchen cooks from.
- **The deployment-target ambush.** `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` sounds
  future-proof but evaluated to iOS **17.0** — every new API use would have needed
  `if #available` gating. Bumped the target-level setting to an explicit 27.0. Lesson: build
  settings that are *indirect* (`$(...)`) can silently mean something very different from
  what the SDK version suggests.
- **`CacheProtocol` died of natural causes.** It referenced the vanishing `Cache.CacheType`,
  had exactly one conformer, and its `preload` signature never even matched the
  implementation (non-async vs async). A protocol with one conformer and no-op defaults is
  scaffolding, not architecture.
- **pbxproj is lava while Xcode is open.** Removing the Kingfisher SPM package requires
  project-file surgery, and editing `project.pbxproj` behind a running Xcode's back risks
  crashing it. Deployment target went through the `UpdateTargetBuildSetting` tool; the
  package removal itself is a two-click job in Xcode's Package Dependencies tab (done by the
  human, as it should be).
- **"Cache Only" showing placeholders is the feature.** `.returnCacheDataDontLoad` fails for
  anything never cached — the placeholder in the `.failure` phase is the demo *demonstrating*.
  Clear Cache → Cache Only → wall of placeholders → Preload → Cache Only → wall of photos.
  That's the whole meetup talk in four taps.

### 2026-09-20 — The Great De-UIKit-ing

Migrated the whole app from UIKit + storyboards to pure SwiftUI in one sitting. War stories:

- **The hosting controller that couldn't.** The old code had a plaintive comment: it *wanted*
  to use `@IBSegueAction` to build the SwiftUI viewer, but `UIHostingController` is generic,
  generics aren't `@objc`-representable, so it fell back to `prepare(for:)` and a mutable
  `DataModel` that got its `paths` injected after construction. That entire dance — hosting
  controller, `DataModel`, segue identifier strings — is now one line:
  `.fullScreenCover { PhotoViewer(paths: settings.imagePaths) }`. The awkwardness wasn't a
  code smell; it was the framework boundary itself.
- **The view controller that was secretly a database.** `MainViewController` had `static`
  functions (`getPhotoCount()` etc.) that *other screens* called to read UserDefaults. A view
  controller moonlighting as a global settings store is how you end up unable to delete
  anything. The fix — an `@Observable AppSettings` in the environment — is also the reason
  the rest of the migration was easy.
- **Settings continuity for free.** The old code persisted segmented-control choices by
  *segment title string* ("Default", "Large"…), and `Cache.CacheType`'s raw values were
  already those exact strings. So `AppSettings` keeps the same keys and values, and a user
  upgrading from the UIKit build keeps every setting. Zero migration code. Sometimes the
  sloppy-looking decision (persisting UI strings) pays off years later.
- **A latent `ForEach` crash, defused.** `StatsView` used `ForEach(data, id: \.self.0)` —
  keying rows by the label string. The stats data contains *three* identical `("", "")`
  separator rows. Duplicate IDs in a `ForEach` are undefined-behavior roulette (usually
  wrong rows, sometimes a crash). Fixed by enumerating: `id: \.offset` — positional identity
  is correct here because the data is immutable per presentation.
- **`UIScreen.main` walk of shame.** `PhotoView` computed its width by walking
  `UIApplication.shared.connectedScenes` to find the key window. Replaced with a
  `Color(.systemGray4).aspectRatio(4/3, contentMode: .fit)` box that the image fills — the
  layout system already knows the width; you never had to ask UIKit.
- **The "Toolkit" selector retired with honors.** Its whole purpose was A/B-ing the UIKit
  table view against the SwiftUI List on the same cache. With UIKit gone (user's call:
  purest migration), the selector, its UserDefaults key (actively removed on first launch),
  and its row in the stats dump all went with it.
- **Gotcha for future storyboard-ectomies:** deleting the storyboards isn't enough. The app
  had *three* things pointing at them: `UISceneStoryboardFile` inside Info.plist's scene
  manifest, plus `INFOPLIST_KEY_UIMainStoryboardFile` and
  `INFOPLIST_KEY_UILaunchStoryboardName` build settings. Miss one and you get a launch-time
  crash about a missing storyboard. All three removed together;
  `INFOPLIST_KEY_UILaunchScreen_Generation = YES` now provides the (previously empty anyway)
  launch screen.

Verified end-to-end on the simulator: launch → stats sheet (no Toolkit row) → full-screen
viewer with real photos → disk usage climbing from Zero KB to 2.7 MB as Kingfisher cached →
slider and cache-type switching live, no crashes.

## Engineer's Wisdom

- **Move state out of view controllers before migrating them.** The single biggest blocker
  wasn't the UI — it was other screens reaching into `MainViewController`'s statics. Once
  `AppSettings` existed, every screen became independently deletable.
- **`didSet` persistence beats save buttons.** The model writes to UserDefaults on every
  mutation; views just bind. Nobody can forget to save because saving isn't a step.
- **Disable during async work.** The old spinner overlay *showed* progress but didn't block
  re-taps — you could queue three cache-clears. The SwiftUI version pairs the overlay with
  `.disabled(isWorking)`. Progress UI that doesn't disable input is only doing half its job.
- **Actions call methods, bodies stay pure.** `MainView`'s buttons reference
  `clearCache` / `preloadCache`; the async-with-overlay pattern lives in one `perform(_:)`
  helper instead of copy-pasted `Task` blocks.
- **Stage code where it will live.** The `Cache/` folder sat in the repo compiling but
  unreferenced for a while before the AsyncImage migration. When the switch happened, the
  views changed but the caching core was already written and reviewed. Staging real code
  beats a design doc when you know the destination.
- **Stable identity or bust.** Both `List`s now use `enumerated()` with explicit ids instead
  of `.indices` / duplicate-prone keys.

## If I Were Starting Over...

- **Start with the settings model, even in a UIKit app.** An observable settings object
  works fine under UIKit; had it existed from day one, the storyboard would never have grown
  static tentacles into other screens.
- **Make `dumpStats` return a real type.** `[(String, String)]` with magic empty-string
  section markers is why the ForEach-ID bug existed. An `enum StatRow { case section(String),
  value(label:String, value:String) }` would make the view trivial and the bug impossible.
- ~~**`Cache.default` should be `let`, not `var`,** and `CacheProtocol` is decorative~~ —
  both fixed by the AsyncImage migration: `Cache.default` is a `let` on a `@MainActor final
  class`, and `CacheProtocol` was deleted outright.
- ~~**The `Cache/` staging folder** is the obvious next chapter~~ — chapter written; see
  "Kingfisher Flies Away" above.
- **The cache directory is still named `AsyncImageDogImages`** — a leftover from the tutorial
  the staging code was lifted from (this app caches houses, not dogs). One-line rename in
  `ImageNetworking.cacheDirectory` whenever it starts to itch; costs any existing cached
  files, which for a demo is nothing.
