import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:unishield_360/config/constants.dart';

/// API Service for communicating with FastAPI backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = ApiConfig.baseUrl;

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.health}'),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Verify voice gender (Module A - The Gatekeeper)
  Future<VoiceVerificationResult> verifyVoice(File audioFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConfig.verifyVoice}'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VoiceVerificationResult(
          success: true,
          gender: data['gender'],
          confidence: data['confidence'].toDouble(),
          message: data['message'],
        );
      } else {
        final error = json.decode(response.body);
        return VoiceVerificationResult(
          success: false,
          gender: 'unknown',
          confidence: 0.0,
          message: error['detail'] ?? 'Voice verification failed',
        );
      }
    } catch (e) {
      return VoiceVerificationResult(
        success: false,
        gender: 'unknown',
        confidence: 0.0,
        message: 'Error: $e',
      );
    }
  }

  /// Moderate chat text (Module C - The Locker Room)
  Future<TextModerationResult> moderateText(String text, {String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.moderateChat}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TextModerationResult(
          success: true,
          isToxic: data['is_toxic'],
          toxicityScore: data['toxicity_score'].toDouble(),
          categories: List<String>.from(data['categories']),
          message: data['message'],
          safeToPost: data['safe_to_post'],
        );
      } else {
        final error = json.decode(response.body);
        return TextModerationResult(
          success: false,
          isToxic: true,
          toxicityScore: 1.0,
          categories: ['error'],
          message: error['detail'] ?? 'Moderation failed',
          safeToPost: false,
        );
      }
    } catch (e) {
      return TextModerationResult(
        success: false,
        isToxic: true,
        toxicityScore: 1.0,
        categories: ['error'],
        message: 'Error: $e',
        safeToPost: false,
      );
    }
  }

  /// Analyze crowd image (Module D - Campus Eye)
  Future<CrowdAnalysisResult> analyzeCrowd(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConfig.analyzeCrowd}'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CrowdAnalysisResult(
          success: true,
          totalPeople: data['total_people'],
          maleCount: data['male_count'],
          femaleCount: data['female_count'],
          malePercentage: data['male_percentage'].toDouble(),
          femalePercentage: data['female_percentage'].toDouble(),
          safetyInsight: data['safety_insight'],
          riskLevel: data['risk_level'],
        );
      } else {
        final error = json.decode(response.body);
        return CrowdAnalysisResult(
          success: false,
          totalPeople: 0,
          maleCount: 0,
          femaleCount: 0,
          malePercentage: 0.0,
          femalePercentage: 0.0,
          safetyInsight: error['detail'] ?? 'Analysis failed',
          riskLevel: 'unknown',
        );
      }
    } catch (e) {
      return CrowdAnalysisResult(
        success: false,
        totalPeople: 0,
        maleCount: 0,
        femaleCount: 0,
        malePercentage: 0.0,
        femalePercentage: 0.0,
        safetyInsight: 'Error: $e',
        riskLevel: 'unknown',
      );
    }
  }

  /// Send safety alert (Module B - Guardian Mode)
  Future<AlertResult> sendAlert({
    required String oderId,
    required String alertType,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.sendAlert}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': oderId,
          'alert_type': alertType,
          'latitude': latitude,
          'longitude': longitude,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlertResult(
          success: data['success'],
          alertId: data['alert_id'],
          message: data['message'],
        );
      } else {
        final error = json.decode(response.body);
        return AlertResult(
          success: false,
          alertId: '',
          message: error['detail'] ?? 'Failed to send alert',
        );
      }
    } catch (e) {
      return AlertResult(
        success: false,
        alertId: '',
        message: 'Error: $e',
      );
    }
  }
}

// Result classes

class VoiceVerificationResult {
  final bool success;
  final String gender;
  final double confidence;
  final String message;

  VoiceVerificationResult({
    required this.success,
    required this.gender,
    required this.confidence,
    required this.message,
  });
}

class TextModerationResult {
  final bool success;
  final bool isToxic;
  final double toxicityScore;
  final List<String> categories;
  final String message;
  final bool safeToPost;

  TextModerationResult({
    required this.success,
    required this.isToxic,
    required this.toxicityScore,
    required this.categories,
    required this.message,
    required this.safeToPost,
  });
}

class CrowdAnalysisResult {
  final bool success;
  final int totalPeople;
  final int maleCount;
  final int femaleCount;
  final double malePercentage;
  final double femalePercentage;
  final String safetyInsight;
  final String riskLevel;

  CrowdAnalysisResult({
    required this.success,
    required this.totalPeople,
    required this.maleCount,
    required this.femaleCount,
    required this.malePercentage,
    required this.femalePercentage,
    required this.safetyInsight,
    required this.riskLevel,
  });
}

class AlertResult {
  final bool success;
  final String alertId;
  final String message;

  AlertResult({
    required this.success,
    required this.alertId,
    required this.message,
  });
}
