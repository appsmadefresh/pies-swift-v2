<h1 align="center">Pies</h1>
<p align="center">Realtime analytics for iOS apps</p>
<p align="center">
    <img src="https://img.shields.io/badge/iOS-17%2B-blue" alt="iOS 17+"/>
    <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-green" alt="SPM Compatible"/>
    <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="License - MIT"/>
</p>

## Overview

Pies tracks installs, sessions, active devices, and in-app purchases for your iOS app — in realtime. Add two lines of code and view your metrics in the Pies dashboard. No IDFA, no App Tracking Transparency prompt required.

**What it tracks automatically:**
- New installs (including reinstalls)
- App sessions
- Daily active devices
- In-app purchases (price, currency, subscription details)

**Requirements:** iOS 17+, Swift 5.9+

## Quick Start

### 1. Install the SDK

In Xcode: **File > Add Package Dependencies**, then enter:

```
https://github.com/appsmadefresh/pies-swift-v2
```

### 2. Get your credentials

Open the Pies dashboard app, tap **+**, and add your app. You'll receive an **App ID** and **API Key**.

### 3. Configure

In your app's entry point, add (must be called on the main thread — do not wrap in a background queue):

```swift
import Pies

// SwiftUI
@main
struct MyApp: App {
    init() {
        Pies.configure(appId: "<YOUR APP ID>", apiKey: "<YOUR API KEY>")
    }
    // ...
}

// UIKit
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    Pies.configure(appId: "<YOUR APP ID>", apiKey: "<YOUR API KEY>")
    return true
}
```

That's it. Run your app and metrics will appear in the Pies dashboard.

## What the SDK does

- **On first launch:** Detects the install and sends a `newInstall` event
- **On each app open:** Sends a `sessionStart` event (debounced — quick background/foreground switches are ignored)
- **Once per day:** Sends a `deviceActiveToday` event (used to calculate DAU/WAU/MAU)
- **On purchase:** Listens for StoreKit 2 transactions and sends purchase details including price, currency, and subscription info
- **Offline:** Events are cached locally and sent when connectivity returns (up to 500 events)

## What it doesn't do

- No IDFA usage — no App Tracking Transparency prompt needed
- No external dependencies — only Apple system frameworks
- No background network activity — events are sent when the app is in the foreground
- No user data collection — only anonymous device and event data

## FAQ

**Do I need App Tracking Transparency to use Pies?**

No. Pies does not use IDFA or any advertising identifiers.

**Does Pies affect my app's launch time?**

Minimal impact. File I/O and keychain operations run off the main thread. The SDK adds ~2ms to launch time.

**What happens if the user is offline?**

Events are cached in local storage and automatically sent when the device comes back online.

**Does Pies interfere with my own StoreKit handling?**

No. The SDK listens to `Transaction.updates` which supports multiple listeners. Your own StoreKit code works independently.

## Support

Open an [Issue](https://github.com/appsmadefresh/pies-swift-v2/issues) or email [support@appsmadefresh.com](mailto:support@appsmadefresh.com).
