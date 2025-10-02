# BidsCube Flutter SDK Test App

This is a comprehensive test application for the BidsCube Flutter SDK that demonstrates all features across all supported platforms.

## Features

- **Multi-platform Support**: Android, iOS, Web, macOS, Linux, Windows
- **Ad Type Testing**: Image, Video, Native, and Banner ads
- **Real-time Logging**: View SDK logs and responses
- **Interactive Testing**: Test different placement IDs and configurations
- **Error Handling**: Test error scenarios and recovery

## Running the Test App

### Prerequisites

1. **Flutter SDK**: Ensure you have Flutter 3.8.1+ installed
2. **Platform-specific requirements**:
   - **Android**: Android Studio with Android SDK
   - **iOS**: Xcode 15.0+ with iOS 13.0+ deployment target
   - **Web**: Chrome or any modern browser
   - **Desktop**: Platform-specific development tools

### Quick Start

1. **Navigate to testApp directory**:

   ```bash
   cd testApp
   ```

2. **Get dependencies**:

   ```bash
   flutter pub get
   ```

3. **Run on your preferred platform**:

   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Web
   flutter run -d web

   # macOS
   flutter run -d macos

   # Linux
   flutter run -d linux

   # Windows
   flutter run -d windows
   ```

### Test App Usage

1. **Launch the app**
2. **Verify SDK initialization** (green checkmark indicates success)
3. **Select ad type** (Image/Video/Native/Banner)
4. **Choose placement ID** (use test IDs or your own)
5. **Tap "Load Ad"** to request the ad
6. **Monitor logs** for detailed information
7. **Interact with ads** to test callbacks

### Test Placement IDs

| Placement ID  | Ad Type | Description                      |
| ------------- | ------- | -------------------------------- |
| `19483`       | Video   | Test video ad with VAST response |
| `test_image`  | Image   | Test image ad                    |
| `test_native` | Native  | Test native ad                   |
| `test_banner` | Banner  | Test banner ad                   |

### Features Demonstrated

- **SDK Initialization**: Proper configuration and setup
- **Ad Loading**: Different ad types and placement IDs
- **Callback Handling**: All ad lifecycle events
- **Error Handling**: Network failures and invalid placements
- **Platform Integration**: Native platform communication
- **Logging**: Real-time SDK logs and debugging

### Troubleshooting

1. **SDK not initializing**:

   - Check network connectivity
   - Verify Flutter dependencies
   - Check console for error messages

2. **Ads not loading**:

   - Verify placement ID is correct
   - Check network connectivity
   - Review logs for error details

3. **Platform-specific issues**:
   - **Android**: Ensure Android SDK is properly configured
   - **iOS**: Check Xcode project settings and deployment target
   - **Web**: Verify browser compatibility
   - **Desktop**: Check platform-specific requirements

### Development

This test app serves as both a demonstration and a development tool for the BidsCube Flutter SDK. It includes:

- Comprehensive error handling
- Real-time logging and debugging
- Interactive testing interface
- Multi-platform compatibility
- Production-ready examples

### Building for Production

To build the test app for production:

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

---

**BidsCube Flutter SDK Test App** - Comprehensive testing and demonstration platform.
