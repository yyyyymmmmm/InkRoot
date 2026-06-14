# iOS Test Package

Use this helper when you need an IPA-like package for internal device testing.

```bash
dart tool/inkroot.dart build ios-unsigned-ipa
```

The output is written to:

```text
build/ios/unsigned/
```

This package is intended for testing. App Store and TestFlight distribution use a separate Apple release process.
