# Troubleshooting Guide

Common issues and their solutions for InkRoot development.

---

## 📋 Table of Contents

- [Build Issues](#build-issues)
- [Runtime Issues](#runtime-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Dependency Issues](#dependency-issues)
- [Database Issues](#database-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)

---

## 🏗️ Build Issues

### Error: Flutter SDK not found

**Problem**:
```
Flutter SDK not found. Define location with flutter.sdk in the local.properties file.
```

**Solution**:
```bash
# Check Flutter installation
flutter doctor

# Set Flutter SDK path (Android)
# Create/edit android/local.properties
flutter.sdk=/path/to/flutter

# macOS example
flutter.sdk=/Users/username/flutter

# Windows example
flutter.sdk=C:\\flutter
```

### Error: Gradle build failed

**Problem**:
```
FAILURE: Build failed with an exception.
```

**Solutions**:
```bash
# 1. Clean build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get

# 2. Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version 8.12
cd ..

# 3. Clear Gradle cache
rm -rf ~/.gradle/caches/

# 4. Check Java version
java -version
# Should be JDK 11 or 21
```

### Error: CocoaPods install failed (iOS)

**Problem**:
```
Error installing CocoaPods. Please try running `pod install` manually.
```

**Solutions**:
```bash
# 1. Update CocoaPods
sudo gem install cocoapods

# 2. Update repo
pod repo update

# 3. Clean and reinstall
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# 4. If still failing, try deintegrate
cd ios
pod deintegrate
pod install
cd ..
```

### Error: Duplicate class found

**Problem**:
```
Duplicate class found in modules
```

**Solution**:
```gradle
// android/app/build.gradle
// Add to dependencies
configurations {
    all {
        exclude group: 'com.android.support', module: 'support-v4'
    }
}
```

---

## 🏃 Runtime Issues

### Error: MissingPluginException

**Problem**:
```
MissingPluginException(No implementation found for method...)
```

**Solutions**:
```bash
# 1. Hot restart (R) instead of hot reload (r)

# 2. Full rebuild
flutter clean
flutter pub get
flutter run

# 3. For iOS, rebuild pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run

# 4. Check plugin registration
# For Android: android/app/src/main/AndroidManifest.xml
# For iOS: ios/Runner/Info.plist
```

### Error: Null check operator used on null value

**Problem**:
```
Null check operator used on a null value
```

**Solution**:
```dart
// Before (causes error)
String value = nullableValue!;

// After (safe)
String value = nullableValue ?? 'default';

// Or check first
if (nullableValue != null) {
  String value = nullableValue;
}
```

### Error: RenderBox was not laid out

**Problem**:
```
RenderBox was not laid out: RenderRepaintBoundary#xxxxx
```

**Solution**:
```dart
// Wrap in Expanded or Flexible
Column(
  children: [
    Expanded(
      child: ListView(...), // Now has bounded height
    ),
  ],
)

// Or give specific height
SizedBox(
  height: 300,
  child: ListView(...),
)
```

---

## 📱 Platform-Specific Issues

### Android: App crashes on startup

**Problem**: App crashes immediately after launch

**Debug Steps**:
```bash
# View logcat
adb logcat | grep -E "AndroidRuntime|flutter"

# Common issues:
# 1. Minimum SDK version too low
# 2. Missing permissions
# 3. ProGuard issues
```

**Solutions**:
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 23 // Check this
    }
}

// If using ProGuard
buildTypes {
    release {
        minifyEnabled false // Try disabling temporarily
    }
}
```

### Android: Permission denied errors

**Problem**:
```
java.lang.SecurityException: Permission denied
```

**Solution**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<!-- Add required permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- For Android 11+, also add: -->
<application
    android:requestLegacyExternalStorage="true">
```

```dart
// Request permission at runtime
import 'package:permission_handler/permission_handler.dart';

final status = await Permission.storage.request();
if (status.isGranted) {
  // Proceed
}
```

### iOS: Code signing issues

**Problem**:
```
Code signing error: No signing certificate found
```

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner in project navigator
3. Go to Signing & Capabilities
4. Select your team
5. Let Xcode manage signing automatically

### iOS: App not appearing on device

**Problem**: Build succeeds but app doesn't show

**Solution**:
```bash
# Trust developer certificate
# On device: Settings → General → Device Management → Trust

# Clean build folder in Xcode
# Product → Clean Build Folder (Shift+Cmd+K)

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

---

## 📦 Dependency Issues

### Error: Version solving failed

**Problem**:
```
Because package_a depends on package_b ^1.0.0...
version solving failed.
```

**Solutions**:
```bash
# 1. Update dependencies
flutter pub upgrade

# 2. Try overriding version
# pubspec.yaml
dependency_overrides:
  package_b: ^2.0.0

# 3. Check for incompatible constraints
flutter pub deps
```

### Error: Package not found

**Problem**:
```
Could not resolve package 'package_name'
```

**Solutions**:
```bash
# 1. Run pub get
flutter pub get

# 2. Clean and get
flutter clean
flutter pub get

# 3. Check internet connection
ping pub.dev

# 4. Use VPN if pub.dev is blocked

# 5. Try pub cache repair
flutter pub cache repair
```

---

## 🗄️ Database Issues

### Error: Database is locked

**Problem**:
```
SqliteException: database is locked
```

**Solution**:
```dart
// Use singleton pattern
class DatabaseService {
  static Database? _database;
  static final _lock = Lock();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    return await _lock.synchronized(() async {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    });
  }
}
```

### Error: Table doesn't exist

**Problem**:
```
SqliteException: no such table: table_name
```

**Solutions**:
```dart
// 1. Check database version and migration
@override
Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE notes (
      id TEXT PRIMARY KEY,
      content TEXT,
      createdAt INTEGER
    )
  ''');
}

// 2. For existing apps, use migration
@override
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('CREATE TABLE new_table ...');
  }
}

// 3. During development, delete and recreate database
await deleteDatabase(path);
```

### Error: Column doesn't exist

**Problem**:
```
SqliteException: no such column: new_column
```

**Solution**:
```dart
// Add migration
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
  }
}

// Update version in openDatabase
await openDatabase(
  path,
  version: 2, // Increment version
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
);
```

---

## 🌐 Network Issues

### Error: Certificate verification failed

**Problem**:
```
HandshakeException: Handshake error in client
```

**Solutions**:
```dart
// 1. Check server certificate is valid
// 2. For self-signed certs in development ONLY:
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
  }
}

// In main.dart (DEVELOPMENT ONLY)
if (kDebugMode) {
  HttpOverrides.global = MyHttpOverrides();
}
```

### Error: Connection timeout

**Problem**:
```
SocketException: OS Error: Connection timed out
```

**Solutions**:
```dart
// Increase timeout
final response = await http
    .get(uri)
    .timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Connection timed out');
      },
    );

// Add retry logic
Future<http.Response> _retryRequest(
  Future<http.Response> Function() request,
  {int maxRetries = 3}
) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
  throw Exception('Max retries exceeded');
}
```

### Error: 401 Unauthorized

**Problem**: API returns 401 error

**Solutions**:
```dart
// 1. Check token is being sent
final response = await http.get(
  uri,
  headers: {
    'Authorization': 'Bearer $token',
  },
);

// 2. Check token hasn't expired
if (response.statusCode == 401) {
  // Refresh token or re-login
  await refreshToken();
  // Retry request
}

// 3. Verify token format is correct
print('Token: $token'); // Debug
```

---

## ⚡ Performance Issues

### Issue: Slow scrolling / janky animations

**Problem**: UI stutters during scrolling

**Solutions**:
```dart
// 1. Use const constructors
const Text('Hello');

// 2. Use RepaintBoundary
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: NoteCard(note: notes[index]),
    );
  },
)

// 3. Use AutomaticKeepAliveClientMixin for tabs
class MyTabView extends StatefulWidget {
  @override
  _MyTabViewState createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Don't forget this!
    return Container();
  }
}

// 4. Optimize images
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 400, // Resize for display
  fit: BoxFit.cover,
)
```

### Issue: High memory usage

**Problem**: App uses too much memory

**Solutions**:
```dart
// 1. Dispose controllers
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  _subscription.cancel();
  super.dispose();
}

// 2. Use ListView.builder instead of ListView
// Bad
ListView(children: notes.map((n) => NoteCard(n)).toList())

// Good
ListView.builder(
  itemCount: notes.length,
  itemBuilder: (context, i) => NoteCard(notes[i]),
)

// 3. Clear image cache periodically
imageCache.clear();
imageCache.clearLiveImages();
```

### Issue: Slow app startup

**Problem**: App takes long to start

**Solutions**:
```dart
// 1. Lazy load heavy resources
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(), // Show splash immediately
      onGenerateRoute: (settings) {
        // Load heavy resources here
      },
    );
  }
}

// 2. Initialize services asynchronously
Future<void> _initServices() async {
  await Future.wait([
    DatabaseService().initialize(),
    PreferencesService().initialize(),
    // ... other services
  ]);
}

// 3. Use deferred loading for large packages
import 'package:large_package/large_package.dart' deferred as large;

// Load when needed
await large.loadLibrary();
large.useFeature();
```

---

## 🆘 Getting Help

If you can't find a solution here:

1. **Check Logs**: Always check Flutter logs first
   ```bash
   flutter logs
   ```

2. **Search Issues**: Look for similar issues
   - [InkRoot Issues](https://github.com/yyyyymmmmm/IntRoot/issues)
   - [Flutter Issues](https://github.com/flutter/flutter/issues)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

3. **Ask for Help**:
   - 📧 Email: inkroot2025@gmail.com
   - 💬 [GitHub Discussions](https://github.com/yyyyymmmmm/IntRoot/discussions)
   - 🐛 [Report Bug](https://github.com/yyyyymmmmm/IntRoot/issues/new)

4. **Provide Information**:
   - Flutter version (`flutter --version`)
   - Error message and stack trace
   - Steps to reproduce
   - Platform (iOS/Android) and version
   - What you've tried

---

<div align="center">

[Back to Development Docs](README.md) | [Debugging Guide](debugging.md)

</div>

