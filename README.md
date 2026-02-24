# Kaset RentShare

แอปพลิเคชันสำหรับนิสิตมหาวิทยาลัยเกษตรศาสตร์ในการเช่าและปล่อยเช่าสิ่งของ

## 🚀 Features

### Core Features (Phase 1)
- ✅ Authentication with KU Email (@ku.th)
- ✅ User Profile Management
- 🚧 Post Rental Listings
- 🚧 Post Rental Requests
- 🚧 Real-time Chat System
- 🚧 Offer System
- 🚧 GPS Handover Tracking
- 🚧 Automatic Contract Generation
- 🚧 Deposit Management
- 🚧 Review & Rating System

### Advanced Features (Phase 2)
- 🚧 ID Card Verification (Verified Badge)
- 🚧 Face Scan (e-KYC)
- 🚧 Push Notifications
- 🚧 Search & Filtering

## 📱 Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Functions
  - Cloud Messaging
- **Maps**: Google Maps API
- **State Management**: Provider
- **PDF Generation**: pdf package

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (^3.8.1)
- Firebase Project
- Google Maps API Key

### Installation

1. **Clone the repository**
   ```bash
   cd d:\Ku_university\Semeter3\2\mobileApp\Kaset_rentandshare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   
   a. Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
   
   b. Enable these services in Firebase Console:
      - Authentication (Email/Password)
      - Firestore Database
      - Cloud Storage
      - Cloud Messaging
   
   c. Download configuration files:
      - **Android**: Download `google-services.json` and place in `android/app/`
      - **iOS**: Download `GoogleService-Info.plist` and place in `ios/Runner/`
   
   d. Run FlutterFire CLI to configure:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

4. **Setup Google Maps**
   
   a. Get API Key from [Google Cloud Console](https://console.cloud.google.com/)
   
   b. Enable these APIs:
      - Maps SDK for Android
      - Maps SDK for iOS
      - Places API
      - Geocoding API
   
   c. Add API Key:
   
   **Android**: Edit `android/app/src/main/AndroidManifest.xml`
   ```xml
   <application>
       <meta-data
           android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY_HERE"/>
   </application>
   ```
   
   **iOS**: Edit `ios/Runner/AppDelegate.swift`
   ```swift
   import GoogleMaps
   
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🗂️ Project Structure

```
lib/
├── config/
│   └── theme.dart              # App theme & colors
├── models/
│   ├── user_model.dart
│   ├── rental_item_model.dart
│   ├── rental_request_model.dart
│   ├── offer_model.dart
│   └── chat_message_model.dart
├── services/
│   └── auth_service.dart       # Firebase authentication
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── rentals/
│   ├── chat/
│   └── profile/
├── widgets/
└── main.dart                   # App entry point
```

## 🔥 Firestore Database Structure

### Collections

#### users
```
{
  uid: string,
  email: string,
  name: string,
  isVerified: boolean,
  rating: number,
  totalRentals: number,
  createdAt: timestamp
}
```

#### rental_items
```
{
  id: string,
  ownerId: string,
  itemName: string,
  category: string,
  condition: string,
  dailyRate: number,
  deposit: number,
  description: string,
  imageUrls: array,
  status: string,
  createdAt: timestamp
}
```

#### rental_requests
```
{
  id: string,
  requesterId: string,
  itemDescription: string,
  category: string,
  startDate: timestamp,
  endDate: timestamp,
  estimatedBudget: number,
  pickupLocation: geopoint,
  locationName: string,
  createdAt: timestamp
}
```

## 👥 Development Team

- Mobile App Development
- Firebase Backend
- UI/UX Design

## 📄 License

This project is developed for educational purposes at Kasetsart University.

## 🆘 Support

For issues and feature requests, please contact the development team.

---

