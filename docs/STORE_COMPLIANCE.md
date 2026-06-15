# Store Compliance

Last updated: 2026-06-15

This document tracks the release checks required before submitting InkRoot to app stores. It is written for maintainers and store-review preparation.

## iOS App Store

Apple requires apps that support account creation to let users initiate account deletion in the app, and says the option should be easy to find in account settings. If a website is required to finish deletion, the app must link directly to that page. Source: [Apple Developer Support](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

Current app-side status:

- In-app path exists at `Settings > Account and Data Deletion`.
- Account page includes the same entry.
- The legal documents hub includes the same entry.
- Public deletion URL is `https://inkroot.cn/account-deletion.html`.

Before App Store submission:

- Confirm `https://inkroot.cn/account-deletion.html` returns HTTP 200.
- Confirm App Store Connect privacy answers match `ios/Runner/PrivacyInfo.xcprivacy` and the public privacy policy.
- Use App Store update delivery only on iOS. Do not show APK or self-update prompts on iOS.
- Build and archive from a clean non-File-Provider directory or CI runner to avoid extended-attribute code signing failures.
- Use a real Apple Developer Team, production bundle id `com.didichou.inkroot`, release signing, and an App Store provisioning profile.

## Google Play

Google Play requires apps with account creation to provide an in-app path for deleting app accounts and associated data, and a web link where users can request account and associated data deletion. The web link must work, be relevant, reference the app or developer name, and make the deletion pathway easy to discover. Source: [Google Play Console Help](https://support.google.com/googleplay/android-developer/answer/13327111).

Current app-side status:

- In-app deletion path exists at `Settings > Account and Data Deletion`.
- Public deletion URL is `https://inkroot.cn/account-deletion.html`.
- Android manifest does not request broad photo/video access or exact-alarm special access. User-created reminders fall back to normal system alarms when exact scheduling is unavailable.

Before Google Play submission:

- Confirm the Data safety form discloses account/profile data, user content, photos/files, optional AI/WebDAV/Memos transfer, feedback, crash diagnostics, and Android analytics only when actually enabled.
- In the account deletion answers, provide `https://inkroot.cn/account-deletion.html`.
- Reminders use normal system alarm fallback on Android 12+ when exact scheduling is unavailable; do not request exact-alarm special access unless the product is changed to a policy-eligible alarm/calendar use case.
- Build the signed AAB with the production keystore and verify upload signing configuration before rollout.

## Release Verification

Run locally or in CI before tagging:

```bash
dart tool/inkroot.dart store-check
dart tool/inkroot.dart verify
dart tool/inkroot.dart build android-release
dart tool/inkroot.dart build android-aab
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-release
dart tool/inkroot.dart build windows-release
dart tool/inkroot.dart build linux-release
```

Platform notes:

- Android builds require Android SDK and release signing secrets. Google Play
  submission should use the signed AAB from `dart tool/inkroot.dart build android-aab`.
- iOS simulator builds validate compile/runtime basics. App Store submission
  requires an Xcode archive with Apple signing assets and App Store Connect
  upload.
- iOS/macOS builds require macOS, Xcode, CocoaPods, and Apple signing assets.
- Windows builds require Windows and Visual Studio C++ desktop components.
- Linux builds require GTK, CMake, Ninja, and system packaging dependencies.
