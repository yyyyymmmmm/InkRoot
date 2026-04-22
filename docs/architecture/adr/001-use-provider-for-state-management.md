# 001. Use Provider for State Management

Date: 2025-01-15

## Status

Accepted

## Context

InkRoot needs a state management solution that:
- Handles complex app state (notes, user data, sync status, UI state)
- Enables reactive UI updates when data changes
- Is easy to understand and maintain
- Has good Flutter ecosystem support
- Performs well with large datasets

Flutter offers several state management solutions:
- Provider (recommended by Flutter team)
- Bloc/Cubit
- Riverpod
- GetX
- Redux
- MobX

The app has multiple screens that need to share state:
- Home screen displays note list
- Note detail screen edits individual notes
- Settings screen configures app behavior
- Multiple screens need user authentication state

## Decision

We will use **Provider** as the primary state management solution for InkRoot.

Specifically:
- Use `ChangeNotifierProvider` for app-wide state (`AppProvider`)
- Implement `ChangeNotifier` for reactive state updates
- Use `Consumer` and `Provider.of<T>()` for accessing state in widgets
- Keep business logic in service classes, not in providers
- Provider handles state coordination, services handle business logic

## Alternatives Considered

### Alternative 1: Bloc/Cubit

**Pros:**
- More structured approach
- Explicit state transitions
- Good for complex state machines
- Excellent testability

**Cons:**
- Steeper learning curve
- More boilerplate code
- Overkill for InkRoot's needs
- Slower development iteration

**Reason for rejection:** Too complex for InkRoot's state management needs. Most of our state updates are straightforward CRUD operations that don't require the ceremony of Bloc.

### Alternative 2: Riverpod

**Pros:**
- Modern, improved version of Provider
- Compile-time safety
- Better testing support
- No BuildContext dependency

**Cons:**
- Newer, smaller community
- Migration path from Provider unclear at the time
- Less documentation and examples
- Team less familiar with it

**Reason for rejection:** While Riverpod is technically superior, Provider has more community support and examples. The team was also more familiar with Provider, enabling faster development.

### Alternative 3: GetX

**Pros:**
- All-in-one solution (routing, state, DI)
- Simple syntax
- Good performance
- Fast development

**Cons:**
- Opinionated framework
- Magic/hidden behavior
- Vendor lock-in
- Doesn't follow Flutter best practices
- Testing can be more difficult

**Reason for rejection:** Too opinionated and deviates from Flutter conventions. The "magic" behavior makes code harder to understand and debug.

## Consequences

### Positive Consequences

- **Official Support**: Provider is recommended by Flutter team
- **Large Community**: Extensive documentation, examples, and community support
- **Simple API**: Easy to learn and understand
- **Good Performance**: Efficient widget rebuilding
- **Testability**: Easy to test with mocked providers
- **Incremental Adoption**: Can start simple and add complexity as needed
- **BuildContext Integration**: Natural fit with Flutter's widget tree

### Negative Consequences

- **BuildContext Dependency**: Requires context to access state (can be verbose)
- **Manual Optimization**: Need to manually optimize rebuilds with `Consumer` vs `Provider.of`
- **No Compile-time Safety**: Errors only caught at runtime
- **Global State**: Easy to create tightly coupled code if not careful
- **Limited Structure**: Less opinionated than Bloc, need to enforce our own patterns

### Neutral Consequences

- **Learning Curve**: Medium learning curve for team members new to Provider
- **Boilerplate**: Some boilerplate for providers and consumers (but less than Bloc)
- **Migration Path**: If we need Riverpod later, migration is possible but requires work

## Implementation Notes

### AppProvider Structure

```dart
class AppProvider with ChangeNotifier {
  // Services (injected dependencies)
  final DatabaseService _databaseService;
  final ApiService _apiService;
  
  // State
  List<Note> _notes = [];
  User? _currentUser;
  bool _isLoading = false;
  
  // Getters
  List<Note> get notes => _notes;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  // Actions
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    
    _notes = await _databaseService.getAllNotes();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> createNote(String content) async {
    final note = await _databaseService.insertNote(content);
    _notes.insert(0, note);
    notifyListeners();
  }
}
```

### Usage in main.dart

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            DatabaseService(),
            ApiService(),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

### Usage in Widgets

```dart
// Method 1: Consumer (rebuilds only this widget)
Consumer<AppProvider>(
  builder: (context, appProvider, child) {
    return ListView.builder(
      itemCount: appProvider.notes.length,
      itemBuilder: (context, index) {
        return NoteCard(note: appProvider.notes[index]);
      },
    );
  },
)

// Method 2: Provider.of (rebuilds entire widget)
final notes = Provider.of<AppProvider>(context).notes;

// Method 3: Provider.of with listen: false (doesn't rebuild)
final appProvider = Provider.of<AppProvider>(context, listen: false);
appProvider.createNote('New note');
```

### Best Practices

1. **Keep providers thin**: Move business logic to services
2. **Minimize notifyListeners()**: Only call when state actually changes
3. **Use Consumer selectively**: Only wrap widgets that need to rebuild
4. **Avoid deep nesting**: Keep provider access close to where it's needed
5. **Test providers**: Write unit tests for provider logic

## References

- [Flutter Provider Documentation](https://pub.dev/packages/provider)
- [Flutter State Management Guide](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Provider Package Best Practices](https://pub.dev/packages/provider#good-practices)
- [Flutter Team Recommendation](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#provider)

