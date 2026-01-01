/// Crowd analysis result model
class CrowdAnalysis {
  final String id;
  final String imageUrl;
  final String analyzedBy;
  final String location;
  final DateTime analyzedAt;
  final int totalPeople;
  final int maleCount;
  final int femaleCount;
  final double malePercentage;
  final double femalePercentage;
  final String safetyInsight;
  final String riskLevel; // 'low', 'medium', 'high'

  CrowdAnalysis({
    required this.id,
    this.imageUrl = '',
    required this.analyzedBy,
    required this.location,
    required this.analyzedAt,
    required this.totalPeople,
    required this.maleCount,
    required this.femaleCount,
    required this.malePercentage,
    required this.femalePercentage,
    required this.safetyInsight,
    required this.riskLevel,
  });

  factory CrowdAnalysis.fromMap(Map<String, dynamic> map, String id) {
    return CrowdAnalysis(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      analyzedBy: map['analyzedBy'] ?? '',
      location: map['location'] ?? 'Unknown',
      analyzedAt: map['analyzedAt']?.toDate() ?? DateTime.now(),
      totalPeople: map['totalPeople'] ?? 0,
      maleCount: map['maleCount'] ?? 0,
      femaleCount: map['femaleCount'] ?? 0,
      malePercentage: (map['malePercentage'] ?? 0.0).toDouble(),
      femalePercentage: (map['femalePercentage'] ?? 0.0).toDouble(),
      safetyInsight: map['safetyInsight'] ?? '',
      riskLevel: map['riskLevel'] ?? 'low',
    );
  }

  factory CrowdAnalysis.fromApiResponse(Map<String, dynamic> response) {
    return CrowdAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      analyzedBy: '',
      location: '',
      analyzedAt: DateTime.now(),
      totalPeople: response['total_people'] ?? 0,
      maleCount: response['male_count'] ?? 0,
      femaleCount: response['female_count'] ?? 0,
      malePercentage: (response['male_percentage'] ?? 0.0).toDouble(),
      femalePercentage: (response['female_percentage'] ?? 0.0).toDouble(),
      safetyInsight: response['safety_insight'] ?? '',
      riskLevel: response['risk_level'] ?? 'low',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'analyzedBy': analyzedBy,
      'location': location,
      'analyzedAt': analyzedAt,
      'totalPeople': totalPeople,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'malePercentage': malePercentage,
      'femalePercentage': femalePercentage,
      'safetyInsight': safetyInsight,
      'riskLevel': riskLevel,
    };
  }

  bool get isHighRisk => riskLevel == 'high';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get isLowRisk => riskLevel == 'low';
}
