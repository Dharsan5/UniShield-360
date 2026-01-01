/// API Configuration for UniShield 360
class ApiConfig {
  // Change this to your server IP/domain in production
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // For iOS simulator
  // static const String baseUrl = 'https://your-domain.com'; // For production
  
  // API Endpoints
  static const String verifyVoice = '/verify-voice';
  static const String moderateChat = '/moderate-chat';
  static const String analyzeCrowd = '/analyze-crowd';
  static const String sendAlert = '/send-alert';
  static const String health = '/health';
}

/// Firebase Collection Names
class FirebaseCollections {
  static const String users = 'users';
  static const String alerts = 'alerts';
  static const String chatMessages = 'chat_messages';
  static const String chatRooms = 'chat_rooms';
  static const String emergencyContacts = 'emergency_contacts';
  static const String crowdAnalytics = 'crowd_analytics';
}

/// App Constants
class AppConstants {
  // Alert Types
  static const String yellowAlert = 'yellow';
  static const String redAlert = 'red';
  
  // User Roles
  static const String roleMale = 'male';
  static const String roleFemale = 'female';
  static const String roleAdmin = 'admin';
  
  // Voice Verification
  static const double voiceConfidenceThreshold = 0.7;
  static const int voiceRecordingDuration = 5; // seconds
  
  // Chat
  static const int maxMessageLength = 500;
  static const double toxicityThreshold = 0.5;
  
  // SOS
  static const int longPressMilliseconds = 3000;
  static const int shakeThreshold = 3;
}

/// Asset Paths
class AssetPaths {
  static const String logo = 'assets/images/logo.png';
  static const String sosAnimation = 'assets/animations/sos.json';
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String voiceAnimation = 'assets/animations/voice.json';
}
