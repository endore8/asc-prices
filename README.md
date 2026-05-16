# Price Localizer

A native macOS app scaffold for managing App Store subscription pricing. Currently set up as an empty app structure — no networking or business logic yet.

## Requirements

- macOS 26+
- Xcode 16+ (Swift 6)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Setup

```sh
xcodegen
open PriceLocalizer.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project PriceLocalizer.xcodeproj -scheme PriceLocalizer build
```

## Project Layout

```
project.yml                         xcodegen config
PriceLocalizer/
  Resources/                        Info.plist, assets (currently empty)
  Sources/
    App/                            App.swift, AppDependencies, AppConstants
    Navigation/                     RootView
    Pages/
      Auth/                         AuthPage (placeholder)
      Main/                         MainPage (placeholder split view)
    Tools/
      Auth/                         Credentials
      Storage/
        KeyValue/                   KeyValueStorage protocol + Keychain struct & conformance
.zed/tasks.json                     Zed editor tasks (Build / Run / Generate)
```

## Zed Tasks

- **Build** — `xcede build PriceLocalizer mac`
- **Run** — `xcede buildrun PriceLocalizer mac`
- **Generate** — `xcodegen`
- **Generate > Build > Run** — chains all three

(Requires the `xcede` xcodebuild wrapper; `xcodegen` runs first when the project structure changes.)
