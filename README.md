# Llumen for iOS

The native iPhone client for Llumen, written in SwiftUI for iOS 27 with Liquid Glass. It covers the four main surfaces of the product: **Findings** (briefings), **Monitor** (a board of live widgets), the **Llumen assistant** chat, and **Profile**.

The app is currently a high-fidelity front end. Content is sample data in the source, the assistant's replies are simulated, and the only network traffic is the Mapbox map tiles.

## Requirements

- Xcode 27 with the iOS 27 SDK (the deployment target is iOS 27.0, iPhone only).
- The **Metal Toolchain** component, needed to compile `MapShimmer.metal`. Xcode prompts for it on first build, or install it with:

  ```sh
  xcodebuild -downloadComponent MetalToolchain
  ```

## Getting started

1. Open `llumen mobile.xcodeproj`.
2. Select the `llumen` scheme and an iPhone simulator or device.
3. Build and run. The app launches signed in, on the Findings tab.

From the command line:

```sh
xcodebuild -project "llumen mobile.xcodeproj" -scheme llumen \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```

The project uses Xcode's synchronized folder groups, so any file added under `llumen/` is part of the target automatically. You don't need to edit `project.pbxproj`.

### Opening a specific screen

`AppModel` reads a `-LlumenScreen <name>` launch argument so you can jump straight to a state. That's useful for screenshots and design review. Add it under *Scheme → Run → Arguments*, or pass it to `simctl`:

```sh
xcrun simctl launch booted com.llumen.mobile -LlumenScreen board
```

| Name | Opens |
| --- | --- |
| `all` (or `latest`) | Findings reel |
| `feedchart` | Findings reel, on a chart stop |
| `alerts`, `updates` | Findings grid in that mode |
| `chip` | A finding shown as a toast |
| `alert` | A finding shown as the full aurora alert |
| `story` | The story player |
| `board` | Monitor board |
| `edit` | Monitor board in edit mode |
| `map`, `chart` | A board widget opened full screen |
| `ask` | Assistant with a briefing attached |
| `chat` | Assistant with a sample conversation |
| `profile` | Profile |
| `signin` | Sign-in screen |

## Project layout

Everything lives in `llumen/`:

| File | What it holds |
| --- | --- |
| `LlumenApp.swift`, `LlumenRoot.swift` | App entry, sign-in gate, environment setup |
| `AppModel.swift` | The single `@Observable` app state: tab, Findings mode, board editing, chat threads, finding alerts |
| `AppShell.swift` | Tab container, floating Liquid Glass tab bar, the Ask button, the bottom blur |
| `BriefingsScreen.swift` | Findings: the All reel (full-screen pages over a live map) and the Alerts / Updates grid |
| `StoryPlayer.swift` | Full-screen, auto-advancing briefing stories |
| `FindingAurora.swift` | Incoming-finding toast and aurora alert (WebGL shader), the Ask button and orb |
| `BoardScreen.swift` | Monitor board: block-grid layout, resizing, filters, widget picker |
| `LumenCharts.swift` | Chart components (columns, area, share bar, ring, horizontal bars) and widget faces |
| `FocusScreen.swift` | A board widget opened full screen |
| `LlumenMapView.swift` | Mapbox GL map in a web view, with the loading shimmer |
| `MapShimmer.metal` | Metal shader for the map loading placeholder |
| `ChatSheet.swift` | Assistant sheet: thread, conversation list, composer, attachments, dictation |
| `ThinkingMesh.swift` | Animated mesh gradient shown while the assistant composes a reply |
| `ProfileScreen.swift`, `SignInScreen.swift` | Profile and sign-in |
| `Theme.swift` | Design tokens (colors, spacing, radii, motion) and font registration |
| `GlassSurface.swift`, `LlumenBackground.swift` | Shared Liquid Glass surfaces and the app background |
| `Phosphor.swift` | Phosphor icon set and renderer |
| `ProgressiveBlur.swift` | Variable-radius backdrop blur |
| `Fonts/` | Innovator Grotesk (UI text) and the Phosphor icon font |
| `AppIcon.icon/`, `Assets.xcassets/` | App icon (Icon Composer) and image assets |

## Design system

- **Tokens:** `Theme` mirrors `llumen-ai-frontend/src/styles/tokens.css`. Colors are dynamic and resolve for both light and dark appearance, and the app follows the system setting.
- **Type:** Innovator Grotesk through `LumenFont.font(size, weight)`. The fonts are registered at launch in `Theme.swift`.
- **Glass:** cards, buttons and the tab bar use system Liquid Glass (`glassEffect`). Primary actions use `blueGlass()`.
- **Motion:** use `Theme.motion` for UI transitions so timing stays consistent.

### Icons

Use `PhosphorIcon(.name, size:)` in views, and `PhosphorMenuLabel` inside menus. To add an icon, look up its codepoint in Phosphor's [regular stylesheet](https://unpkg.com/@phosphor-icons/web/src/regular/style.css) and add a case to the `Phosphor` enum.

Icons are drawn from the font's glyph outlines and adjusted so every icon has the same line width (`Phosphor.strokeWidth`, 1.25pt), whatever its size. Changing that one value makes every icon in the app bolder or lighter.

## Notable implementation details

- **Bottom blur:** `ProgressiveBlur` uses Core Animation's `variableBlur` filter on a `UIVisualEffectView` backdrop, with a gradient mask, so the blur ramps up toward the bottom edge. This is a private API looked up by name at runtime. If it's ever unavailable, the code skips the filter rather than crashing. The view re-applies the filter when UIKit rebuilds its layers, for example on appearance changes.
- **Maps:** Mapbox GL JS runs in a `WKWebView`. Camera and blur changes are sent to the page only when they differ from what's shown. The page posts a message on Mapbox's first `idle` event, which is when the Metal shimmer fades out. The Mapbox token and style are in `MapboxFeed` (`LlumenMapView.swift`).
- **Map shimmer:** `MapShimmer.metal` draws drifting topographic contours with a light sweep. Line width is measured in points, so contours look the same on every widget size. It pauses when Reduce Motion is on.
- **Aurora:** the finding alert shader runs in one shared WebGL canvas, created at launch and kept warm. It only draws frames while the aurora is visible.
- **Dictation:** the chat composer uses the microphone and speech recognition. The usage descriptions are set in the build settings.
