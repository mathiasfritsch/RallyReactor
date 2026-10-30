# Native iOS POC without a Mac

Build a native SwiftUI iPhone app on GitHub Actions, download an unsigned `.ipa`, and install it on your iPhone using Sideloadly on Windows.

No Apple Developer Program, App Store Connect keys, or local Mac are required for the POC.

## Stack

| Component | Choice |
|---|---|
| App | Native Swift / SwiftUI |
| Code editing | Windows or Linux, e.g. VS Code or Rider |
| iOS build | GitHub Actions macOS runner |
| Build output | Unsigned `.ipa` artifact |
| Installation | Sideloadly on Windows |
| Signing | Your normal Apple ID |
| Testing | Physical iPhone |

## Limitations

- Free Apple ID signatures expire after **7 days**.
- A free Apple ID allows up to **3 sideloaded apps per device**.
- Re-sign the same IPA with Sideloadly to refresh the app.
- Avoid entitlements such as App Groups, iCloud, or push notifications for the first POC.

## 1. Create a simple iOS project

Create an Xcode project named `PocApp` with:

- One target: `PocApp`
- One shared scheme: `PocApp`
- A basic SwiftUI view
- No App Store capabilities

Without a Mac, the `.xcodeproj` is generated on the runner by [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`; the workflow runs `xcodegen generate` before `xcodebuild`.

Example `ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("iOS POC works")
                .font(.title)

            Text("Built without owning a Mac")
        }
        .padding()
    }
}
```

Commit the project to a GitHub repository.

## 2. Add GitHub Actions workflow

Create:

```text
.github/workflows/build-ios.yml
```

```yaml
name: Build unsigned iOS POC

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build unsigned app
        run: |
          xcodebuild \
            -project PocApp.xcodeproj \
            -scheme PocApp \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            DEVELOPMENT_TEAM="" \
            PROVISIONING_PROFILE_SPECIFIER="" \
            build

      - name: Package unsigned IPA
        run: |
          APP_PATH=$(find build/Build/Products -type d -name "PocApp.app" | head -n 1)
          test -n "$APP_PATH"

          mkdir -p ipa/Payload
          cp -R "$APP_PATH" ipa/Payload/

          cd ipa
          zip -qry ../PocApp-unsigned.ipa Payload

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: PocApp-unsigned-ipa
          path: PocApp-unsigned.ipa
          if-no-files-found: error
```

Replace `PocApp` with your actual project, target, and scheme name.

## 3. Build the IPA

1. Push the repository to GitHub.
2. Open **Actions**.
3. Select **Build unsigned iOS POC**.
4. Click **Run workflow**.
5. Download the artifact when the job succeeds.
6. Extract it to obtain `PocApp-unsigned.ipa`.

## 4. Install on iPhone

1. Install [Sideloadly](https://sideloadly.io/) on Windows.
2. Connect the iPhone by USB and unlock it.
3. Open Sideloadly.
4. Drag `PocApp-unsigned.ipa` into the IPA field.
5. Enter your normal Apple ID.
6. Click **Start**.
7. On the iPhone, open **Settings → General → VPN & Device Management**.
8. Trust the developer profile.
9. Enable **Developer Mode** if prompted:
   - **Settings → Privacy & Security → Developer Mode**
10. Launch the app from the Home Screen.

## 5. Refresh after 7 days

After seven days, the app stops launching.

To refresh:

1. Open Sideloadly.
2. Select the same `.ipa`.
3. Use the same Apple ID.
4. Install it again.

Sideloadly can overwrite the existing installation while preserving app data.

## Common issues

| Problem | Fix |
|---|---|
| Scheme not found | Run `xcodebuild -list -project PocApp.xcodeproj` in the workflow to list schemes |
| Project uses CocoaPods | Replace `-project` with `-workspace` and run `pod install` before `xcodebuild` |
| Signing errors | Ensure all `CODE_SIGN_*` flags are present |
| App requires entitlements | Remove App Groups, iCloud, push notifications, etc. for the POC |
| App expires | Re-sign and reinstall using Sideloadly |

## POC success criteria

- GitHub Actions produces `PocApp-unsigned.ipa`
- Sideloadly installs it on your physical iPhone
- The app launches successfully
- You can change the SwiftUI UI, rebuild, and install the update