# UniShield 360

**An Integrated Campus Safety & Wellness Platform**

> "A safe campus isn't just about emergencies; it's about mental well-being and smart monitoring."

## 🎯 Overview

UniShield 360 is a comprehensive mobile platform that connects students to safety resources, provides anonymous mental health support, and enables real-time campus monitoring through AI-powered analytics.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
├─────────────────────────────────────────────────────────────────┤
│  ├─ Firebase Auth (Login / Roles)                               │
│  ├─ REST API calls (FastAPI)                                    │
│  │    ├─ /verify-voice                                          │
│  │    ├─ /moderate-chat                                         │
│  │    └─ /analyze-crowd                                         │
│  └─ Firebase Firestore (Chat, Alerts, GPS)                      │
├─────────────────────────────────────────────────────────────────┤
│                      FastAPI (Python)                            │
├─────────────────────────────────────────────────────────────────┤
│  ├─ Voice Gender Model (Librosa)                                │
│  ├─ Text Moderation (NLTK / transformers)                       │
│  └─ Image Gender Counter (YOLO + OpenCV)                        │
└─────────────────────────────────────────────────────────────────┘
```

## 🎭 User Roles

| Role | Access |
|------|--------|
| **Female Student** | Guardian Mode (Safety Alert) |
| **Male Student** | BroCode (Anonymous Stress Sharing) |
| **Admin/Security** | Campus Eye (Gender Stats & Analytics) |

## 📱 Modules

### Module A: The Gatekeeper (Voice Gender Verification)
- **Usage**: During sign-up/onboarding
- **Flow**: User reads "I am a student at this university" aloud
- **AI**: Analyzes voice to determine gender
- **Result**: Automatically unlocks appropriate features

### Module B: Guardian Mode (Women's Safety)
- **Features**:
  - 🟡 **Single Tap**: Yellow Alert - "I'm uncomfortable, track me"
  - 🔴 **Long Press (3s) / Shake**: Red Alert - Emergency notification
- **Notifications**: Campus Security + Parents + Friends
- **Extras**: Live GPS tracking, background service

### Module C: The Locker Room (Men's Stress Sharing)
- **Access**: Exclusively for verified male users
- **Features**:
  - Anonymous posting with random avatars
  - Real-time chat in topic-based rooms
  - AI sentiment check prevents bullying
  - Support reactions for peer encouragement

### Module D: Campus Eye (Admin Dashboard)
- **Access**: Admin/Security personnel only
- **Features**:
  - Photo-based crowd analysis
  - Gender distribution statistics
  - Safety insights and risk levels
  - Actionable recommendations

## 🚀 Quick Start

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Download NLTK data
python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords')"

# Configure environment
cp .env.example .env
# Edit .env with your Firebase credentials

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Configure Firebase
# 1. Create Firebase project at console.firebase.google.com
# 2. Run: flutterfire configure
# 3. Enable Authentication (Email/Password)
# 4. Create Firestore database

# Update API URL in lib/config/constants.dart

# Run app
flutter run
```

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Service health check |
| `/verify-voice` | POST | Voice gender verification |
| `/moderate-chat` | POST | Text toxicity analysis |
| `/analyze-crowd` | POST | Crowd gender analysis |
| `/send-alert` | POST | Safety alert dispatch |

## 📦 Tech Stack

### Frontend (Flutter)
- **State Management**: Provider
- **Auth & Database**: Firebase (Auth, Firestore)
- **Audio**: record, audioplayers
- **Location**: geolocator, google_maps_flutter
- **UI**: flutter_animate, lottie, fl_chart

### Backend (Python FastAPI)
- **Voice Analysis**: Librosa
- **Text Moderation**: transformers (toxic-bert)
- **Object Detection**: Ultralytics YOLOv8
- **Image Processing**: OpenCV, Pillow

## 🔐 Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Alerts - users can create, admins can read all
    match /alerts/{alertId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Chat messages - verified males only
    match /chat_messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.gender == 'male';
    }
  }
}
```

## 📁 Project Structure

```
unishield_360/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   ├── config.py            # Configuration
│   │   └── services/
│   │       ├── voice_verification.py
│   │       ├── text_moderation.py
│   │       └── crowd_analyzer.py
│   ├── requirements.txt
│   └── README.md
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart
    │   ├── config/
    │   │   └── constants.dart
    │   ├── theme/
    │   │   └── app_theme.dart
    │   ├── models/
    │   ├── services/
    │   ├── providers/
    │   ├── screens/
    │   │   ├── auth/
    │   │   ├── onboarding/
    │   │   ├── home/
    │   │   ├── guardian/
    │   │   ├── brocode/
    │   │   ├── admin/
    │   │   └── profile/
    │   └── widgets/
    └── pubspec.yaml
```

## 🎨 Color Scheme

| Module | Color | Hex |
|--------|-------|-----|
| Primary | Purple | `#6C63FF` |
| Guardian | Pink | `#E91E63` |
| BroCode | Blue | `#2196F3` |
| Campus Eye | Purple | `#9C27B0` |
| Emergency | Red | `#FF4444` |
| Warning | Yellow | `#FFBB33` |
| Safe | Green | `#00C851` |

## 🏆 Hackathon Problem Statements Addressed

1. ✅ **Women Safety**: Guardian Mode with SOS alerts
2. ✅ **Men's Mental Health**: Anonymous stress sharing (BroCode)
3. ✅ **Voice Gender Detection**: AI-powered verification
4. ✅ **Crowd Gender Analytics**: YOLO-based analysis

## 👥 Team

Built for university hackathon - UniShield 360 Team

## 📄 License

MIT License - Feel free to use and modify for educational purposes.

---

**Remember**: Safety is everyone's responsibility. UniShield 360 - Protecting what matters. 🛡️
