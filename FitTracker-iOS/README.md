# FitTracker iOS - Native SwiftUI Fitness App

A comprehensive native iOS fitness tracking application built with SwiftUI, converted from the original React/Next.js PWA. This app maintains all the functionality of the web version while providing native iOS performance and integrations.

## 🚀 Features

### Core Functionality
- **6-Tab Navigation**: Dashboard, Workout, Nutrition, Social, Progress, Health
- **Workout Tracking**: Complete exercise database with session management
- **Focus Mode**: Distraction-free workout experience with timer and restrictions  
- **Exercise Search**: Advanced filtering by muscle group, equipment, and difficulty
- **Progress Analytics**: Workout statistics, streaks, and progression tracking
- **Social Features**: User profiles, posts, comments, and follow system
- **Nutrition Tracking**: Food database, meal logging, and macro tracking
- **Challenge System**: Individual and team challenges with leaderboards
- **Health Integration**: Apple Health and HealthKit integration

### iOS-Specific Enhancements
- **Native Navigation**: UIKit/SwiftUI navigation patterns
- **Haptic Feedback**: Tactile feedback for interactions
- **Core Data Integration**: Robust local data persistence
- **Native Notifications**: Local and push notification support
- **Camera Integration**: Barcode scanning for nutrition tracking
- **Background Processing**: Workout tracking in background
- **Widget Support**: Home screen widgets for quick stats
- **Siri Shortcuts**: Voice control for common actions

## 📱 Screenshots & Demo

*To be added once the app is running in Xcode*

## 🏗️ Architecture

### Project Structure
```
FitTracker-iOS/
├── FitTrackerApp.swift          # Main app entry point
├── ContentView.swift            # Main tab navigation
├── Models/                      # Data models and Core Data
│   ├── Exercise.swift
│   ├── Nutrition.swift
│   ├── Social.swift
│   ├── Challenge.swift
│   └── PersistenceController.swift
├── Views/                       # SwiftUI views
│   ├── DashboardView.swift
│   ├── WorkoutView.swift
│   ├── WorkoutSessionView.swift
│   ├── ExerciseSearchView.swift
│   ├── FocusModeView.swift
│   └── NutritionView.swift
├── Services/                    # Business logic and data services
│   ├── WorkoutService.swift
│   ├── ExerciseDatabase.swift
│   ├── NutritionService.swift
│   └── SocialService.swift
├── ViewModels/                  # MVVM ViewModels
├── Extensions/                  # Swift extensions
├── Utils/                       # Utility functions
└── Info.plist                  # App configuration
```

### Design Patterns
- **MVVM Architecture**: Clean separation of concerns
- **ObservableObject/StateObject**: Reactive state management
- **Combine Framework**: Reactive programming for data flow
- **Core Data**: Local data persistence and synchronization
- **Service Layer**: Centralized business logic and API calls

## 🛠️ Setup & Installation

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later
- Apple Developer Account (for device testing)

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd FitTracker-iOS
   ```

2. **Open in Xcode**
   ```bash
   open FitTracker.xcodeproj
   ```

3. **Configure Bundle Identifier**
   - Select the project in Xcode
   - Update Bundle Identifier to your unique identifier
   - Configure Team and Signing

4. **Set up Core Data**
   - The Core Data model will be auto-generated
   - Ensure data model is configured in project settings

5. **Configure Permissions**
   - Health permissions are pre-configured in Info.plist
   - Camera permission for barcode scanning
   - Location permission for outdoor workouts

6. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Required Capabilities
Add these capabilities in Xcode project settings:
- **HealthKit**: For health data integration
- **Camera**: For barcode scanning
- **Background Processing**: For workout tracking
- **Push Notifications**: For social and challenge notifications

## 🔧 Configuration

### Info.plist Setup
The included Info.plist contains all necessary permissions:
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription  
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSMotionUsageDescription

### Core Data Configuration
Core Data is configured with these entities:
- WorkoutEntity
- ExerciseEntity
- NutritionEntity
- UserEntity
- ChallengeEntity

## 📊 Feature Comparison

| Feature | PWA Version | iOS Native |
|---------|-------------|------------|
| Offline Support | ✅ Service Worker | ✅ Core Data |
| Push Notifications | ✅ Web Push | ✅ Native Push |
| Camera Access | ✅ WebRTC | ✅ Native Camera |
| Health Integration | ❌ | ✅ HealthKit |
| App Store Distribution | ❌ | ✅ |
| Background Processing | ❌ | ✅ |
| Haptic Feedback | ❌ | ✅ |
| Siri Integration | ❌ | ✅ |
| Widget Support | ❌ | ✅ |

## 🧪 Testing

### Unit Tests
Run unit tests with:
```bash
xcodebuild test -scheme FitTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
UI tests are configured for critical user flows:
- Workout creation and completion
- Exercise search and selection
- Focus mode functionality
- Navigation between tabs

## 🚀 Deployment

### TestFlight Distribution
1. Archive the project (`Product > Archive`)
2. Upload to App Store Connect
3. Configure TestFlight testing
4. Distribute to beta testers

### App Store Release
1. Complete App Store Connect metadata
2. Submit for review
3. Handle review feedback
4. Release to App Store

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit pull request with description

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code consistency
- Include documentation for public APIs
- Write unit tests for business logic

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Original PWA implementation for feature specification
- SwiftUI community for UI component inspiration
- Apple Developer Documentation
- Fitness tracking community for domain expertise

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the documentation wiki
- Join the community discussions

---

**Built with ❤️ using SwiftUI and iOS native technologies**