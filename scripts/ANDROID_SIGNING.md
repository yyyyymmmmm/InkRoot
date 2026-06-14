# Android Signing

InkRoot Android release builds use a local keystore or GitHub Secrets.

## Local Signing

Expected local files:

```text
android/key.properties
android/inkroot-new-release.keystore
```

These files are ignored by Git.

`android/key.properties` must contain:

```properties
storeFile=../inkroot-new-release.keystore
storePassword=...
keyAlias=...
keyPassword=...
```

Build a signed release APK:

```bash
dart tool/inkroot.dart build android-release
```

Build an unsigned debug APK:

```bash
dart tool/inkroot.dart build android-debug
```

## GitHub Actions Signing

Configure repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_STORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Create the base64 keystore value on macOS:

```bash
base64 -i android/inkroot-new-release.keystore | pbcopy
```

Create it on Linux:

```bash
base64 -w 0 android/inkroot-new-release.keystore
```

Then run the `CI` workflow manually with `release_build=true`.

## Security

Never commit keystores, passwords, GitHub tokens, or signing certificates. If a
credential is exposed, revoke and rotate it immediately.
