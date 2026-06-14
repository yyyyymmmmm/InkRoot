# Changelog

All notable changes to InkRoot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.2] - 2026-06-15

### Fixed
- Fixed account profile loading failures after a successful Memos login on some servers
- User profile loading now falls back across v0.21, v0.22-v0.25, and v0.26+ account APIs instead of relying on a single detected version
- Requests now send both Bearer Token and Memos Cookie credentials for better compatibility with official and self-hosted servers
- Login errors now distinguish credential, token, network, TLS, and server response failures instead of showing one generic network message

### Verified
- Verified official server login on the iOS simulator and synced 279 notes successfully
- `flutter analyze` passed
- Memos API unit tests passed

---

## [1.1.1] - 2026-06-15

### Fixed
- Improved Memos login compatibility when servers hide version information before login
- Fixed Flutter default icons still appearing on Windows desktop builds
- Unified macOS and Windows desktop icon generation

### Maintenance
- Added `scripts/generate_desktop_icons.py` for desktop icon asset generation

---

## [1.1.0] - 2026-06-14

### Maintenance and Release Workflow
- Added the unified maintenance CLI: `dart tool/inkroot.dart`
- Upgraded GitHub Actions to validate and build Android, iOS simulator, macOS, Windows, and Linux
- Added PR template, issue templates, Dependabot configuration, and Gitleaks secret scanning
- Added `docs/MAINTENANCE.md` for versioning, CI, release, and security workflow
- Added tag-driven release publishing through GitHub Actions

### Quality
- `flutter analyze` currently reports 0 issues
- `flutter test` currently passes 300 tests
- iOS simulator launch was verified

### Fixed
- Cloud configuration failure responses with string `msg` no longer trigger Dart type errors
- Added model tests for successful and failed cloud verification responses

## [1.0.9] - 2025-11-22 ~ 2025-11-24

### ✨ Major Feature Updates

#### 🔄 **Notion Data Sync** - Real-time Sync with Notion Workspace (Added 2025-11-24)
- **Bidirectional Sync Support**
  - To Notion Only - Local Notes → Notion
  - From Notion Only - Notion → Local Notes
  - Bidirectional - Local Notes ↔ Notion
  - Flexible sync direction for different use cases

- **Auto Sync Feature**
  - Auto sync when creating notes
  - Auto sync when editing notes
  - Pull-to-refresh triggers sync
  - Smart duplicate sync prevention

- **Notion Settings Page**
  - Access token configuration and testing
  - Database selection and field mapping
  - Sync direction selection
  - Auto sync toggle
  - Manual sync button

- **Technical Implementation**
  - Added `NotionApiService` - Notion API wrapper
  - Added `NotionSyncService` - Notion sync logic
  - Added `notion_settings_screen.dart` - Notion settings UI
  - Integrated auto-sync logic in `AppProvider`

#### 📓 **Obsidian Integration** - Bidirectional Sync via Third-party Plugin (Added 2025-11-24)
- **Plugin Compatibility**
  - Fully compatible with [obsidian-memos-sync](https://github.com/RyoJerryYu/obsidian-memos-sync) plugin
  - Supports Memos API v0.21.0 standard
  - Supports daily notes auto-integration
  - Supports incremental sync

- **Import/Export Page Integration**
  - Added Obsidian data sync entry
  - Click to jump to plugin download page
  - Professional feature descriptions
  - Unified UI design style

#### 📖 **WeRead Notes Import** - Batch Import Reading Notes (Added 2025-11-24)
- **Smart Parsing**
  - Auto-recognize book information (title, author)
  - Auto-parse note count and chapters
  - Smart extract note content
  - Preserve original structure and format

- **Import Settings**
  - Custom tags (default: WeRead + book title)
  - Chapter as secondary tag option
  - Preview and check before import
  - Batch import progress display

- **User Experience**
  - Detailed usage instructions
  - Friendly paste area hints
  - Format check and validation
  - Import result statistics

- **Technical Implementation**
  - Added `WeReadParser` - WeRead notes parsing service
  - Added `weread_import_screen.dart` - WeRead import page
  - Smart text parsing algorithm
  - Supports multiple note formats

### 🎨 UI/UX Optimization

#### Import/Export Page Text Refinement (Added 2025-11-24)
- **Professional Expression**
  - Local Backup & Restore: Export note data to local files, supports data recovery from backup files
  - Flomo Notes Import: Supports batch import of note content from Flomo exported HTML files
  - WeRead Notes Import: Supports batch import from WeRead exported notes text with automatic book info and highlight recognition
  - Notion Data Sync: Real-time sync with Notion workspace, supports bidirectional and auto-sync
  - Obsidian Data Sync: Bidirectional sync with Obsidian via third-party plugin, supports daily notes integration
  - Memos Browser Extension: Third-party browser extension, supports Chrome/Edge, quickly collect web content to Memos

- **Unified Terminology**
  - "Plugin" → "Extension"
  - "Save" → "Collect"
  - "Colloquial" → "Professional"

- **Data Security Tips**
  - 💡 Data Security Tip: Regular backup of note data is recommended. Please confirm file format before import to avoid data loss.

### 🌍 Internationalization Support

#### New Translations
- **Notion Sync** (30+ strings)
  - All Notion settings UI text
  - Sync direction options and descriptions
  - Auto-sync related text
  - Error messages and success notifications

- **Obsidian Integration** (5+ strings)
  - Obsidian sync title and description
  - Plugin download guide text

- **WeRead Import** (20+ strings)
  - All import page text
  - Usage instructions and hints
  - Advanced options descriptions
  - Import result messages

- **Import/Export Page** (10+ strings)
  - All feature card titles and descriptions
  - Data security tip text

### 🔧 Technical Improvements

#### New Files
- `lib/services/notion_api_service.dart` - Notion API service
- `lib/services/notion_sync_service.dart` - Notion sync service
- `lib/services/weread_parser.dart` - WeRead parsing service
- `lib/screens/notion_settings_screen.dart` - Notion settings page
- `lib/screens/weread_import_screen.dart` - WeRead import page

#### Modified Files
- `lib/providers/app_provider.dart` - Integrated Notion auto-sync
- `lib/screens/home_screen.dart` - Pull-to-refresh triggers Notion sync
- `lib/screens/import_export_main_screen.dart` - Added Notion/Obsidian/WeRead entries
- `lib/l10n/app_localizations_simple.dart` - Added 80+ i18n strings

#### Architecture Optimization
- Notion sync uses async non-blocking design
- Duplicate sync prevention mechanism
- Smart error handling and logging
- Modular service design

### 📊 Statistics

- New files: 5
- Modified files: 15+
- New code: ~3500 lines
- New i18n strings: 80+ (Chinese & English)
- New features: 3 major features (Notion/Obsidian/WeRead)

### 🔗 Related Links

- [Obsidian Memos Sync Plugin](https://github.com/RyoJerryYu/obsidian-memos-sync)
- [Notion API Documentation](https://developers.notion.com/)
- [Memos v0.21.0](https://github.com/usememos/memos/releases/tag/v0.21.0)

#### 📝 **Annotation System** - Professional Note Annotation (2025-11-22)
- **Annotation Sidebar** - Professional design aligned with mainstream note apps
  - Bottom slide-out sidebar with draggable height adjustment
  - Responsive layout, perfectly adapted for phones, tablets, and desktops
  - Annotation type filtering (All/Comment/Question/Idea/Important/To-do)
  - Annotation count statistics and real-time updates
  - Friendly empty state prompts

- **Multiple Annotation Types** - Meet different scenario needs
  - 💬 Comment - General annotations
  - ❓ Question - Record questions
  - 💡 Idea - Inspiration recording
  - ⭐ Important - Key marking
  - ✅ To-do - Task reminders
  - Each type with dedicated icon and color

- **Annotation Management**
  - Add annotation: Support type selection and content input
  - Edit annotation: Modify content and type
  - Delete annotation: Confirmation dialog prevents accidental deletion
  - Mark as resolved: To-do type can mark completion status
  - Time display: Smart relative time (just now/minutes ago/hours ago/days ago)

- **Annotation Entry Optimization**
  - Home note cards: Display annotation icon and count in bottom right
  - Click annotation icon: Directly open annotation sidebar
  - Note detail page: "View Annotations" option in more menu
  - Detail page bottom: Annotation area display and quick add

#### 🔗 **Reference Sidebar** - New Reference Management Experience (2025-11-22)
- **Reference Sidebar Design** - Consistent with annotation sidebar
  - Bottom slide-out design, draggable adjustment
  - Responsive layout for multiple devices
  - Reference type filtering (All/Referenced Notes/Referenced By)
  - Reference count statistics

- **Reference Relationship Visualization**
  - ↗️ Referenced Notes (Forward references) - Blue indicator
  - ↙️ Referenced By (Backlinks) - Green indicator
  - Reference cards show note preview and creation time
  - Click card to jump directly to corresponding note

- **Reference Entry Optimization**
  - Home note cards: Display reference arrow and count
  - Click arrow: Directly open reference sidebar
  - Note detail page: "Reference Details" option in more menu

#### 🎨 **AI Settings Enhancement** - Custom AI Prompts (2025-11-22)
- **Custom Prompt Support**
  - Insight Prompt
  - Review Prompt
  - Continuation Prompt
  - Tag Insight Prompt
  - Tag Recommendation Prompt

- **Prompt Management**
  - Each prompt has clear description and scope
  - Supports multi-line input for complex prompts
  - Leave empty to use system default prompts
  - Real-time save, immediate effect

### 🌍 **Complete Internationalization** - Seamless Chinese/English Switching

#### Annotation Feature Internationalization
- Annotation sidebar: Title, filtering, empty state, time format
- Annotation types: Comment/Question/Idea/Important/To-do
- Annotation dialogs: Add, edit, delete
- Success messages: Annotation added/updated/deleted/marked as resolved

#### Reference Feature Internationalization
- Reference sidebar: Title, filtering, empty state
- Reference types: Referenced Notes/Referenced By
- Reference cards: Type labels, time display

#### AI Settings Internationalization
- Custom prompts: All titles and descriptions
- Input hints: All prompt text
- Help information: Scope descriptions

#### Note Detail Page Internationalization
- Annotation area: Title, buttons, empty state prompts

### 🎨 UI/UX Improvements

- **Unified Sidebar Design** - Annotations and references use consistent design language
  - Smooth bottom slide-out animation
  - Supports draggable height adjustment (0.5-0.95 screen height)
  - Modern rounded corners
  - Perfect dark mode adaptation

- **Responsive Layout** - Perfectly adapted for multiple devices
  - Phone: Full screen display
  - Tablet: 80% width
  - Desktop: Fixed 400px width

- **Interaction Optimization**
  - Click annotation/reference icon to directly open sidebar
  - Annotation type selection uses ChoiceChip, more intuitive
  - Filter buttons support icon+text, clearer
  - Friendly empty state prompts guide user operations

### 🐛 Bug Fixes

- Fixed annotation dialog displaying as boxes on home page
- Fixed AI settings custom prompts displaying as boxes
- Fixed reference arrow click not responding
- Fixed annotation type text not using internationalization
- Fixed time formatting method call errors
- Fixed duplicate declaration compilation errors

### 🔧 Technical Improvements

- **Code Structure Optimization**
  - Added `AnnotationsSidebar` component
  - Added `ReferencesSidebar` component
  - Optimized `NoteActionsService` service
  - Enhanced `AppLocalizationsSimple` internationalization

- **Performance Optimization**
  - Annotation sidebar uses Provider listening, real-time updates
  - Reference relationship calculation optimization, reduced duplicate queries
  - Internationalization text caching, improved rendering performance

### 📊 Statistics

- New files: 2 (AnnotationsSidebar, ReferencesSidebar)
- Modified files: 10+
- New i18n strings: 50+
- Lines of code: +2000
- Supported languages: Chinese, English

---

## [1.0.8] - 2025-10-30

### 🌍 Added
- **Complete Internationalization Support** - Chinese/English bilingual switching
- All UI and messages fully internationalized
- Custom translation system using `translations.dart`
- Dynamic language switching without app restart

### 🏷️ Enhanced Tag System
- Multi-level tag support (`#parent/child`)
- Tree-view display with collapse/expand
- AI-powered related tag recommendations
- Tag statistics and visualization
- Custom tag colors

### 📥 Flomo Notes Import
- Import notes from Flomo HTML files
- Smart parsing of content and tags
- Preserve original creation time
- Auto image migration and compression
- Smart deduplication (content match + exact match)
- Use relative paths for images to avoid path invalidation

### ⚡ Performance Optimization
- AI API call efficiency improved by 50%
- WebDAV sync performance optimization with incremental sync support
- Image compression optimization (1200x1200, 85% quality)
- Project size reduced by 400-600MB

### 🐛 Critical Fixes
- Fixed image path issues (images not displaying after iOS upgrade)
- Changed to relative path storage, dynamic parsing to absolute paths
- Fixed UI layout overflow issues
- Fixed tag parsing exceptions
- Optimized sync conflict handling

---

## [1.0.7] - 2025-09-15

### Added
- **Knowledge Graph** - Visualize note relationships
- **Activity Heatmap** - Track note creation habits with month switching
- **Note Pinning** - Pin important notes with cloud sync support
- **Custom Fonts** - 4 font sizes + 6 selected fonts

### Improved
- Enhanced search functionality
- Optimized sync performance
- Improved UI/UX

### Fixed
- Various bug fixes and stability improvements

---

## [1.0.6] - 2025-08-01

### Added
- **AI Smart Assistant** - DeepSeek AI integration
- **Voice Recognition** - Real-time speech-to-text
- **Smart Reminders** - Scheduled notifications
- **Random Review** - Smart recommendation of historical notes

### Improved
- Enhanced Markdown rendering
- Optimized image handling
- Improved performance

---

## [1.0.5] - 2025-07-01

### Added
- **Local References** - Bidirectional note linking with `[[Note Title]]`
- **Backlinks** - Auto-display which notes reference current note
- **WebDAV Sync** - Multi-device sync support

### Improved
- Enhanced tag system
- Optimized UI design
- Improved stability

---

## [1.0.0] - 2025-06-01

### Added
- Initial release
- Basic note-taking functionality
- Markdown support
- Tag system
- Image management
- Dark mode
- Cloud sync with Memos server
- Local mode support

---

For more details, visit our [GitHub Repository](https://github.com/yyyyymmmmm/InkRoot).
