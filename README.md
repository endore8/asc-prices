# Price Localizer

A native macOS app for previewing PPP-aligned App Store subscription prices across territories using the Netflix Index.

Connect with an App Store Connect API key, pick an app and subscription, choose an index and a base country, and get a side-by-side diff of current vs. PPP-equivalent prices in every territory.

## Requirements

- macOS 15+
- Xcode 16+ (Swift 6)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- App Store Connect API key with the **App Manager** role (download the `.p8` from App Store Connect → Users and Access → Integrations → App Store Connect API)

## Setup

```sh
xcodegen
open PriceLocalizer.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project PriceLocalizer.xcodeproj -scheme PriceLocalizer build
```

## First Run

1. Click **Choose .p8 file…** and pick the API key you downloaded from App Store Connect. The Key ID is auto-detected from filenames like `AuthKey_ABC123DEFG.p8`.
2. Paste the **Issuer ID** (UUID at the top of the Keys tab in App Store Connect).
3. Click **Save & Continue**. Credentials are stored in the macOS Keychain under `com.endore8.price-localizer`.

## Usage

- **Sidebar** lists your apps.
- **Middle column** shows the selected app's subscriptions.
- **Detail** shows current per-territory prices in a table.
- Pick an **Index**, a **Base country**, and a **Base price** from Apple's available price points for that country.
- Click **Preview** to see the calculated PPP-equivalent target prices alongside the current ones, with `Δ%` colored green/red.

The apply step (writing prices back to App Store Connect) is not yet implemented.

## Project Layout

```
project.yml             xcodegen config
Sources/
  App/                  app entry, RootView, AppSession
  Auth/                 Keychain, JWT signer (CryptoKit ES256), Credentials
  Networking/           AscClient, TokenCache, per-resource APIs
  Indices/              PriceIndex protocol, NetflixIndex, registry
  Pricing/              PppCalculator
  Util/                 TerritoryName (alpha-3 → display name)
  Views/                AuthView, MainSplitView, PricesDetailView, BaseCountryPicker
Resources/              static resources (currently empty)
.zed/tasks.json         Zed editor tasks (Build / Run / Generate)
```

## Zed Tasks

- **Build** — `xcede build PriceLocalizer mac`
- **Run** — `xcede buildrun PriceLocalizer mac`
- **Generate** — `xcodegen`
- **Generate > Build > Run** — chains all three

(Requires the `xcede` xcodebuild wrapper; `xcodegen` runs first when the project structure changes.)

## Sign Out

The toolbar has a sign-out button that clears the Keychain entry. The base country preference (UserDefaults) is preserved across sign-outs.
