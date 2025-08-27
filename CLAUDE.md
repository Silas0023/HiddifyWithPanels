# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HiddifyWithPanels is a cross-platform Flutter application that provides a multi-protocol proxy frontend with panel integration. It supports Android, iOS, macOS, Windows, and Linux platforms.

## Key Architecture

### Core Components

1. **Singbox Core**: Native proxy core library in `libcore/` that handles the actual proxy connections
2. **Flutter App**: Main UI application in `lib/` using Riverpod for state management
3. **Platform Channels**: Platform-specific implementations in `android/`, `ios/`, `macos/`, `windows/`, `linux/`
4. **Panel Integration**: XBoard panel support with authentication, purchases, and subscriptions in `lib/features/panel/xboard/`

### Main Features

- Profile management for proxy configurations
- Connection management with VPN/system proxy support  
- Per-app proxy configuration (Android)
- Panel integration with user authentication and plan purchases
- Geo-asset management for routing rules
- Real-time connection statistics

## Common Issues and Fixes

### Dependency Conflicts
- If you encounter `intl` version conflicts, update `pubspec.yaml` to use `intl: ^0.20.2` and `humanizer: ^3.0.1`
- If `custom_lint_core` causes build runner issues, disable it in `analysis_options.yaml` by commenting out the custom_lint plugin

## Development Commands

### Prerequisites and Setup

```bash
# Platform-specific preparation (choose one)
make android-prepare  # Android development
make ios-prepare      # iOS development  
make macos-prepare    # macOS development
make linux-prepare    # Linux development
make windows-prepare  # Windows development

# These commands will:
# 1. Run flutter pub get
# 2. Generate code with build_runner
# 3. Generate translations
# 4. Download platform-specific libcore binaries
```

### Common Development Tasks

```bash
# Run the app in development mode
flutter run

# Generate code (models, routes, database)
dart run build_runner build --delete-conflicting-outputs

# Generate translations
dart run slang

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### Building Releases

```bash
# Android
flutter build apk --target lib/main_prod.dart  # APK for distribution
flutter build appbundle --target lib/main_prod.dart  # AAB for Play Store

# iOS
flutter build ios --target lib/main_prod.dart

# macOS  
flutter build macos --target lib/main_prod.dart

# Windows
flutter build windows --target lib/main_prod.dart

# Linux
flutter build linux --target lib/main_prod.dart
```

### Platform-specific Release Packaging

```bash
# Android releases
make android-apk-release  # Build APK
make android-aab-release  # Build AAB for Play Store

# Desktop releases using flutter_distributor
make windows-release  # Creates exe and msix packages
make linux-release    # Creates deb, rpm, and appimage packages  
make macos-release    # Creates dmg and pkg packages
make ios-release      # Creates ipa package
```

## Code Architecture

### State Management
- Uses Riverpod with code generation for dependency injection and state management
- Notifiers pattern for business logic (`*_notifier.dart` files)
- Repository pattern for data access (`*_repository.dart` files)

### Database
- Drift ORM for local SQLite database
- Schema versioning and migrations in `lib/core/database/`
- Tables defined in `lib/core/database/tables/`

### Routing
- go_router for navigation with code generation
- Routes defined in `lib/core/router/`

### Platform Integration
- Method channels for platform-specific features
- Service implementations vary by platform (VPN on mobile, system proxy on desktop)
- Background service support on Android

### Localization
- Uses slang for type-safe translations
- Translation files in `assets/translations/`
- Supports multiple languages including English, Chinese, Persian, Arabic, etc.

## Important Patterns

### Adding New Features
1. Create feature folder in `lib/features/`
2. Implement data layer (repository, data sources)
3. Create notifier for business logic
4. Build UI widgets
5. Add routes if needed

### Working with Singbox Core
- Core binaries are downloaded during preparation
- FFI bindings in `lib/gen/singbox_generated_bindings.dart`
- Service abstraction in `lib/singbox/service/`
- Platform-specific implementations handle the core differently

### Panel Integration
- XBoard API integration in `lib/features/panel/xboard/services/`
- Authentication state managed globally
- Subscription synchronization with panel