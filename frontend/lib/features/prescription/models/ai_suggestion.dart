import 'dart:ui';

import 'package:flutter/material.dart';

class AISuggestion {
  final String medication;
  final double confidence;
  final String category;
  final String? reason;

  AISuggestion({
    required this.medication,
    required this.confidence,
    required this.category,
    this.reason,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      medication: json['medication'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication': medication,
      'confidence': confidence,
      'category': category,
      if (reason != null) 'reason': reason,
    };
  }

  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  Color get confidenceColor {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'antihypertenseur':
        return Icons.favorite;
      case 'antiulcéreux':
        return Icons.medical_services;
      case 'antibiotique':
        return Icons.healing;
      case 'analgésique':
        return Icons.local_hospital;
      case 'antidiabétique':
        return Icons.bloodtype;
      default:
        return Icons.medication;
    }
  }
}

class AISuggestionsResponse {
  final bool success;
  final String consultationId;
  final List<AISuggestion> suggestions;
  final bool aiAvailable;
  final String? processingTime;
  final int totalMedications;
  final String? error;

  AISuggestionsResponse({
    required this.success,
    required this.consultationId,
    required this.suggestions,
    required this.aiAvailable,
    this.processingTime,
    required this.totalMedications,
    this.error,
  });

  factory AISuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return AISuggestionsResponse(
      success: json['success'] ?? false,
      consultationId: json['consultationId'] ?? '',
      suggestions: (json['suggestions'] as List?)
              ?.map((s) => AISuggestion.fromJson(s))
              .toList() ??
          [],
      aiAvailable: json['ai_available'] ?? false,
      processingTime: json['processing_time'],
      totalMedications: json['total_medications'] ?? 0,
      error: json['error'],
    );
  }
}
