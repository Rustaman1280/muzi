# Muziek

A Flutter music player app with modern audio features and local music library support.

## Package Information
- **App Name**: Muziek
- **Package Name**: com.crustdev.muziek
- **Platform**: Android (minSdkVersion 21+)

## Features

### Core Features
- 🎵 Local music library scanning
- 🎧 High-quality audio playback
- 📱 Modern Material Design 3 UI
- 🔄 Background audio playback
- 📋 Playlist management
- 🔍 Music search and filtering

### Technical Features
- **Navigation**: go_router for type-safe routing
- **State Management**: hooks_riverpod + flutter_hooks
- **Audio Engine**: just_audio with audio_service for background playback
- **Local Storage**: Hive for fast local data storage
- **Permissions**: Proper Android/iOS permission handling
- **Metadata**: ID3 tag reading support

## Dependencies

### Core Dependencies
```yaml
# Routing/UI
go_router: ^14.6.2
hooks_riverpod: ^2.6.1
flutter_hooks: ^0.20.5

# Audio
just_audio: ^0.9.42
audio_session: ^0.1.21
audio_service: ^0.18.15
rxdart: ^0.28.0

# File/Metadata
on_audio_query: ^2.9.0
permission_handler: ^11.3.1
path_provider: ^2.1.4
id3: ^1.0.2

# Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# Utils/UI
cached_network_image: ^3.4.1
collection: ^1.18.0
```

## Project Structure

```
lib/
├── app/                    # App-level configuration
│   └── app.dart           # Main app widget with routing
├── core/                   # Core business logic
│   ├── database/          # Database services (Hive)
│   ├── models/            # Data models
│   ├── services/          # Business logic services
│   └── utils/             # Utility functions
├── features/              # Feature modules
│   ├── home/             # Home screen
│   ├── player/           # Audio player
│   ├── library/          # Music library
│   ├── download/         # Download management
│   └── settings/         # App settings
└── shared/               # Shared components
    ├── constants/        # App constants
    ├── providers/        # Riverpod providers
    └── widgets/          # Reusable widgets
```

## Platform Configuration

### Android
- **minSdkVersion**: 21 (Android 5.0+)
- **Media playback service** configured for background audio
- **Notification channel** for media controls
- **Storage permissions** for local music access


## Setup and Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd muziek
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Development

### Key Services
- **AudioPlayerService**: Handles audio playback with just_audio
- **MusicQueryService**: Scans and manages local music library
- **PermissionService**: Manages system permissions
- **HiveService**: Local data storage management

### State Management
The app uses Riverpod for state management with the following key providers:
- `audioPlayerServiceProvider`: Audio player instance
- `currentSongProvider`: Currently playing song
- `songListProvider`: Music library
- `permissionsProvider`: System permissions status

## Permissions

The app requires the following permissions:
- **Storage**: Access to local music files
- **Audio**: Audio playback capabilities
- **Notifications**: Media playback notifications (Android 13+)

## Build Configuration

### Android
- Configured for media playback with foreground service
- Custom application ID: com.crustdev.muziek
- minSdkVersion 21 for modern audio features

## Contributing

1. Follow the established folder structure
2. Use Riverpod for state management
3. Implement proper error handling
4. Add tests for new features
5. Follow Flutter/Dart style guidelines
