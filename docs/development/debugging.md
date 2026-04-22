# Debugging Guide

This guide covers debugging techniques and tools for InkRoot development.

---

## 📋 Table of Contents

- [Debug Build](#debug-build)
- [Logging](#logging)
- [Flutter DevTools](#flutter-devtools)
- [Debugging UI](#debugging-ui)
- [Debugging State](#debugging-state)
- [Debugging Network](#debugging-network)
- [Debugging Database](#debugging-database)
- [Platform-Specific Debugging](#platform-specific-debugging)
- [Common Issues](#common-issues)

---

## 🏗️ Debug Build

### Run in Debug Mode

```bash
# Run on connected device
flutter run

# Run with verbose logging
flutter run -v

# Run on specific device
flutter run -d <device-id>

# Hot reload (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
```

### Enable Debug Mode in Code

```dart
// lib/config/app_config.dart
class AppConfig {
  static const bool debugMode = true;
  static const bool verboseLogging = true;
  static const bool enableNetworkLogging = true;
}
```

---

## 📝 Logging

### Using Logger Service

```dart
import 'package:inkroot/services/logger_service.dart';

final logger = LoggerService();

// Different log levels
logger.debug('Debug message');
logger.info('Info message');
logger.warning('Warning message');
logger.error('Error message', error: e, stackTrace: st);
```

### View Logs

```bash
# Flutter logs
flutter logs

# Filter by tag
flutter logs | grep "InkRoot"

# Android logcat
adb logcat | grep flutter

# iOS logs (requires device connection)
idevicesyslog | grep InkRoot
```

### Custom Log Output

```dart
// Print with source information
void debugLog(String message, {String tag = 'InkRoot'}) {
  if (AppConfig.debugMode) {
    final now = DateTime.now();
    print('[$tag] ${now.toString()}: $message');
  }
}
```

---

## 🛠️ Flutter DevTools

### Launch DevTools

```bash
# Install DevTools
flutter pub global activate devtools

# Run DevTools
flutter pub global run devtools

# Or use VSCode/Android Studio integration
# In VSCode: Press F5, then open DevTools from debug toolbar
```

### Key Features

#### 1. Inspector
- View widget tree
- Inspect widget properties
- Debug layout issues
- Toggle debug paint
- Show performance overlay

#### 2. Timeline
- Analyze frame rendering
- Identify jank
- View GPU/CPU usage
- Track async operations

#### 3. Memory
- Track memory usage
- Find memory leaks
- Analyze heap snapshots
- Monitor allocations

#### 4. Network
- View HTTP requests
- Inspect request/response
- Monitor WebSocket connections
- Debug API calls

#### 5. Logging
- View all logs
- Filter by level
- Search logs
- Export logs

---

## 🎨 Debugging UI

### Debug Paint

```dart
// Show debug paint (layout borders)
void main() {
  debugPaintSizeEnabled = true;
  runApp(MyApp());
}
```

### Widget Inspector

```dart
// Add inspector key to any widget
Container(
  key: Key('my-container'),
  child: Text('Debug me'),
)
```

### Layout Debugging

```dart
// Show baseline
debugPaintBaselinesEnabled = true;

// Show layer borders
debugPaintLayerBordersEnabled = true;

// Show pointer hit test
debugPaintPointersEnabled = true;
```

### Performance Overlay

```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

### Breakpoints in Build Method

```dart
@override
Widget build(BuildContext context) {
  // Add breakpoint here to inspect state
  debugger(); // Pauses execution
  
  return Container(
    child: Text(_myState),
  );
}
```

---

## 🔄 Debugging State

### Provider Debugging

```dart
class AppProvider with ChangeNotifier {
  void _updateState() {
    // Add debug print before notifying
    if (AppConfig.debugMode) {
      print('State update: $_currentState');
    }
    notifyListeners();
  }
}
```

### State Inspection

```dart
// In widget
@override
Widget build(BuildContext context) {
  final appProvider = Provider.of<AppProvider>(context);
  
  // Debug current state
  if (AppConfig.debugMode) {
    print('Building with ${appProvider.notes.length} notes');
  }
  
  return ListView(...);
}
```

### Debugging Provider Rebuilds

```dart
// Track widget rebuilds
int _buildCount = 0;

@override
Widget build(BuildContext context) {
  _buildCount++;
  print('Build count: $_buildCount');
  
  return Consumer<AppProvider>(
    builder: (context, provider, child) {
      print('Consumer rebuilt');
      return Text(provider.someValue);
    },
  );
}
```

---

## 🌐 Debugging Network

### Enable Network Logging

```dart
// In ApiService
class ApiService {
  http.Client? _client;
  
  ApiService() {
    if (AppConfig.enableNetworkLogging) {
      _client = http.Client();
      // Log all requests
    }
  }
  
  Future<http.Response> _loggedRequest(
    String method,
    Uri uri,
    Map<String, String>? headers,
    dynamic body,
  ) async {
    print('→ $method ${uri.toString()}');
    print('Headers: $headers');
    if (body != null) print('Body: $body');
    
    final response = await http.post(uri, headers: headers, body: body);
    
    print('← ${response.statusCode}');
    print('Response: ${response.body}');
    
    return response;
  }
}
```

### Using Charles Proxy / Fiddler

```bash
# Set proxy for debugging
flutter run --dart-define=HTTPS_PROXY=localhost:8888
```

### Debugging HTTPS

```dart
// ONLY FOR DEBUGGING - DO NOT USE IN PRODUCTION
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
  }
}

// In main.dart (debug only)
void main() {
  if (AppConfig.debugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(MyApp());
}
```

---

## 🗄️ Debugging Database

### Enable SQL Logging

```dart
class DatabaseService {
  Future<void> _logQuery(String query, List<dynamic>? args) async {
    if (AppConfig.debugMode) {
      print('SQL: $query');
      if (args != null && args.isNotEmpty) {
        print('Args: $args');
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    _logQuery(
      'SELECT ${columns?.join(', ') ?? '*'} FROM $table WHERE $where',
      whereArgs,
    );
    return await _database.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
```

### Inspect Database

```bash
# Android: Pull database from device
adb pull /data/data/com.didichou.inkroot/databases/inkroot.db ./debug_db.db

# Open with SQLite browser
sqlite3 debug_db.db

# Or use GUI tool
# - DB Browser for SQLite
# - SQLiteStudio
# - DBeaver
```

### Database Debugging Queries

```sql
-- Check table structure
.schema notes

-- Count records
SELECT COUNT(*) FROM notes;

-- View recent notes
SELECT * FROM notes ORDER BY createdAt DESC LIMIT 10;

-- Check for orphaned records
SELECT * FROM note_tags WHERE note_id NOT IN (SELECT id FROM notes);
```

---

## 📱 Platform-Specific Debugging

### Android Debugging

#### Logcat

```bash
# View all logs
adb logcat

# Filter by app
adb logcat | grep com.didichou.inkroot

# Filter by tag
adb logcat -s flutter

# Save to file
adb logcat > logcat.txt
```

#### Android Studio Profiler

1. Open Android Studio
2. Run → Profile 'app'
3. View CPU, Memory, Network, Energy

#### ADB Commands

```bash
# List devices
adb devices

# Install APK
adb install app-release.apk

# Clear app data
adb shell pm clear com.didichou.inkroot

# View app files
adb shell run-as com.didichou.inkroot ls /data/data/com.didichou.inkroot
```

### iOS Debugging

#### Xcode Console

1. Open Xcode
2. Window → Devices and Simulators
3. Select device
4. View device logs

#### Instruments

1. Open Xcode
2. Product → Profile
3. Select profiling template:
   - Time Profiler (CPU)
   - Allocations (Memory)
   - Leaks (Memory Leaks)
   - Network

#### iOS Logs

```bash
# View device logs (requires libimobiledevice)
brew install libimobiledevice
idevicesyslog | grep InkRoot

# Save to file
idevicesyslog > ios_logs.txt
```

---

## 🐛 Common Issues

### Issue 1: Hot Reload Not Working

**Symptoms**: Changes don't appear after hot reload

**Solutions**:
```bash
# Try hot restart (R) instead of hot reload (r)
# Or full restart
flutter run

# Clean build
flutter clean
flutter pub get
flutter run
```

### Issue 2: Widget Not Rebuilding

**Symptoms**: UI doesn't update when state changes

**Debug Steps**:
```dart
// Check if notifyListeners() is being called
class AppProvider with ChangeNotifier {
  void updateData() {
    _data = newData;
    print('Notifying listeners'); // Add this
    notifyListeners();
  }
}

// Check if Consumer is being used correctly
Consumer<AppProvider>(
  builder: (context, provider, child) {
    print('Consumer rebuild'); // Add this
    return Text(provider.data);
  },
)
```

### Issue 3: Memory Leak

**Symptoms**: App becomes slower over time, high memory usage

**Debug**:
1. Open DevTools → Memory
2. Take heap snapshot
3. Compare snapshots
4. Look for objects that aren't being disposed

**Common Causes**:
```dart
// Forgetting to dispose controllers
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose(); // Don't forget this!
    super.dispose();
  }
}
```

### Issue 4: Slow Performance

**Symptoms**: Janky animations, dropped frames

**Debug**:
1. Open DevTools → Timeline
2. Record interaction
3. Look for expensive frames (>16ms)
4. Identify bottlenecks

**Common Solutions**:
```dart
// Use const constructors
const Text('Hello');

// Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ExpensiveWidget(),
)

// Avoid rebuilding entire tree
Consumer<AppProvider>(
  builder: (context, provider, child) {
    return ExpensiveWidget(
      data: provider.data,
      child: child, // This doesn't rebuild
    );
  },
  child: StaticWidget(), // Cached child
)
```

### Issue 5: Database Locked

**Symptoms**: Database errors about locks

**Solutions**:
```dart
// Ensure proper database initialization
class DatabaseService {
  static Database? _database;
  static final _lock = Lock();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Use lock to prevent concurrent initialization
    return await _lock.synchronized(() async {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    });
  }
}
```

---

## 🔍 Advanced Debugging

### Debugging Production Builds

```dart
// Add debug endpoints for production
class DebugService {
  static Map<String, dynamic> getDebugInfo() {
    return {
      'version': AppConfig.appVersion,
      'build': AppConfig.buildNumber,
      'noteCount': Provider.of<AppProvider>(context, listen: false).notes.length,
      'isOnline': connectivity.isOnline,
      'lastSync': lastSyncTime,
    };
  }
}

// Access via settings screen (only visible to developers)
```

### Remote Debugging

```dart
// Integrate Sentry for error tracking
import 'package:sentry_flutter/sentry_flutter.dart';

await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_DSN';
    options.environment = AppConfig.environment;
  },
  appRunner: () => runApp(MyApp()),
);

// Manually capture errors
try {
  // risky operation
} catch (e, stackTrace) {
  await Sentry.captureException(e, stackTrace: stackTrace);
}
```

---

## 📚 Resources

- [Flutter Debugging Documentation](https://flutter.dev/docs/testing/debugging)
- [DevTools Documentation](https://flutter.dev/docs/development/tools/devtools)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Android Debug Bridge (ADB)](https://developer.android.com/studio/command-line/adb)

---

<div align="center">

[Back to Development Docs](README.md) | [Troubleshooting Guide](troubleshooting.md)

</div>

