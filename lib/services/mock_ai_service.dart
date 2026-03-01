import 'dart:async';

class AIReporterResult {
  final String severity;
  final String summary;
  final List<String> recommendedNgos;

  AIReporterResult({
    required this.severity,
    required this.summary,
    required this.recommendedNgos,
  });
}

class MockAIService {
  Future<AIReporterResult> analyzeCase(String description, String url) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 3));

    final descLower = description.toLowerCase();
    
    // Simple mock logic for severity
    if (descLower.contains('kill') || 
        descLower.contains('die') || 
        descLower.contains('hurt') ||
        descLower.contains('weapon') ||
        descLower.contains('immediate')) {
      return AIReporterResult(
        severity: 'High',
        summary: 'Immediate Threat Detected. High risk of physical or severe psychological harm.',
        recommendedNgos: ['ngo_high_1', 'ngo_high_2', 'ngo_high_3'], // Mock IDs
      );
    } else {
      return AIReporterResult(
        severity: 'Medium',
        summary: 'Harassment Detected. Case requires timely intervention and support.',
        recommendedNgos: ['ngo_med_1', 'ngo_med_2', 'ngo_med_3'], // Mock IDs
      );
    }
  }
}
