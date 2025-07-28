# Firebase Setup Instructions for FitTracker

This document provides comprehensive instructions for setting up Firebase for the FitTracker iOS app.

## Prerequisites

- Google Cloud Console access
- Firebase CLI installed
- Xcode project ready

## 1. Firebase Project Setup

### Step 1: Enable Required APIs in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `reps-faf75`
3. Navigate to "APIs & Services" > "Library"
4. Enable the following APIs:
   - **Cloud Firestore API**
   - **Firebase Authentication API**
   - **Cloud Storage for Firebase API**
   - **Firebase Cloud Messaging API**
   - **Firebase Remote Config API**

### Step 2: Configure Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `reps-faf75`
3. Navigate to "Firestore Database"
4. Click "Create database"
5. Choose "Start in test mode" (temporarily)
6. Select a location (recommend `us-central1` for performance)

### Step 3: Set up Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable the following providers:
   - **Email/Password**
   - **Google** (optional)
   - **Apple** (recommended for iOS)

## 2. iOS App Configuration

### Step 1: Add GoogleService-Info.plist

1. In Firebase Console, go to "Project settings"
2. Scroll to "Your apps" section
3. Click on your iOS app or add a new one
4. Download `GoogleService-Info.plist`
5. Add it to your Xcode project root

### Step 2: Install Firebase SDK

The project already includes Firebase dependencies in the Swift Package Manager configuration.

## 3. Firestore Security Rules

Deploy the security rules to protect user data:

```bash
firebase deploy --only firestore:rules
```

The rules file (`firestore.rules`) includes:
- User privacy protection
- Post visibility controls
- Follow/unfollow security
- Workout and meal data protection

## 4. Firestore Collections Structure

The app uses the following Firestore collections:

### Users Collection (`users`)
```javascript
{
  id: "user_id",
  username: "unique_username",
  displayName: "Display Name",
  avatar: "https://image_url",
  bio: "User bio",
  stats: {
    workouts: 0,
    followers: 0,
    following: 0,
    totalVolume: 0.0
  },
  joinDate: timestamp,
  isVerified: false,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Social Posts Collection (`social_posts`)
```javascript
{
  id: "post_id",
  userId: "user_id",
  type: "workout|progress|achievement|general",
  content: "Post content",
  media: ["image_urls"],
  workoutData: {
    exerciseName: "Exercise Name",
    weight: 225.0,
    reps: 8,
    sets: 3,
    duration: 3600
  },
  achievementData: {
    type: "pr|streak|milestone",
    title: "Achievement Title",
    description: "Description",
    value: "Value"
  },
  likes: 0,
  likedBy: ["user_ids"],
  comments: [],
  createdAt: timestamp,
  location: "Location Name",
  tags: ["tags"],
  visibility: "public|friends|private"
}
```

### Workouts Collection (`workouts`)
```javascript
{
  id: "workout_id",
  userId: "user_id",
  name: "Workout Name",
  date: timestamp,
  exercises: [
    {
      id: "exercise_id",
      exerciseId: "wger_exercise_id",
      name: "Exercise Name",
      category: "Strength",
      primaryMuscles: ["chest", "triceps"],
      secondaryMuscles: ["shoulders"],
      equipment: "Barbell",
      sets: [
        {
          id: "set_id",
          reps: 8,
          weight: 225.0,
          restTime: 120,
          completed: true,
          rpe: 8,
          notes: "Felt strong",
          duration: 30,
          timestamp: timestamp
        }
      ],
      notes: "Exercise notes",
      targetSets: 3,
      targetReps: 8,
      targetWeight: 225.0,
      restTime: 120,
      imageUrls: ["exercise_images"]
    }
  ],
  duration: 3600,
  completed: true,
  notes: "Great workout",
  templateId: "template_id",
  tags: ["push", "chest"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Meals Collection (`meals`)
```javascript
{
  id: "meal_id",
  userId: "user_id",
  date: timestamp,
  mealType: "breakfast|lunch|dinner|snack",
  foods: [
    {
      id: "food_entry_id",
      food: {
        id: "food_id",
        name: "Food Name",
        brand: "Brand Name",
        barcode: "1234567890",
        calories: 100.0,
        protein: 25.0,
        carbs: 5.0,
        fat: 3.0,
        fiber: 2.0,
        sugar: 1.0,
        sodium: 200.0,
        category: "Protein",
        servingSize: 100.0,
        servingUnit: "g",
        isVerified: true,
        imageUrl: "food_image_url"
      },
      actualServingSize: 150.0
    }
  ],
  notes: "Meal notes",
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Follows Collection (`follows`)
```javascript
{
  followerId: "user_id",
  followingId: "user_id",
  createdAt: timestamp
}
```

## 5. Offline Persistence

The app automatically enables Firestore offline persistence for improved performance:

```swift
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
db.settings = settings
```

## 6. Real-time Updates

The app uses Firestore real-time listeners for:
- Social feed updates
- User profile changes
- Workout data synchronization
- Follower/following updates

## 7. Error Handling and Retry Logic

All Firestore operations include:
- Proper error handling
- Timeout configurations
- Retry logic for failed operations
- Offline fallback mechanisms

## 8. Performance Optimization

### Indexing
Firestore automatically creates single-field indexes. For complex queries, create composite indexes:

1. Go to Firestore console
2. Navigate to "Indexes" tab
3. Add composite indexes for:
   - `social_posts`: `userId`, `createdAt` (descending)
   - `workouts`: `userId`, `date` (descending)
   - `meals`: `userId`, `date` (ascending)
   - `follows`: `followerId`, `createdAt`

### Query Optimization
- Use pagination with `limit()` and `startAfter()`
- Implement proper caching strategies
- Use real-time listeners efficiently

## 9. Security Best Practices

1. **Never store sensitive data** in Firestore documents
2. **Use security rules** to protect user data
3. **Validate all inputs** on the client side
4. **Implement proper authentication** flows
5. **Regular security rule audits**

## 10. Monitoring and Analytics

1. Enable Firebase Performance Monitoring
2. Set up Crashlytics for error tracking
3. Use Firebase Analytics for user behavior insights
4. Monitor Firestore usage and costs

## 11. Backup and Recovery

1. Enable automatic backups in Firebase console
2. Set up export schedules for critical data
3. Test restore procedures regularly

## 12. Deploy Commands

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy cloud functions (if any)
firebase deploy --only functions

# Deploy all
firebase deploy
```

## Troubleshooting

### Common Issues

1. **Firestore API not enabled**: Enable in Google Cloud Console
2. **Security rules too restrictive**: Test with Firebase console simulator
3. **Offline persistence issues**: Clear app data and restart
4. **Authentication errors**: Check GoogleService-Info.plist configuration

### Debug Tools

1. Firebase console for data inspection
2. Xcode console for error logs
3. Firebase Emulator Suite for local testing
4. Firebase Performance Monitoring dashboard

For additional support, refer to the [Firebase documentation](https://firebase.google.com/docs) or contact the development team.