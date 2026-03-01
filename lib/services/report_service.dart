import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mock_ai_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final MockAIService _mockAI = MockAIService();
  final _random = Random();

  /// Generates a random alphanumeric string of [length]
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))));
  }

  /// Wait 2 seconds and return a dummy hash
  Future<String> generateBlockchainHash(String url) async {
    await Future.delayed(const Duration(seconds: 2));
    final randomHex = List.generate(12, (_) => _random.nextInt(16).toRadixString(16)).join('');
    return '0x7f3$randomHex';
  }

  /// Uploads media to Firebase Storage and returns the download URL.
  Future<String?> _uploadEvidence(File? file, String caseId) async {
    if (file == null) return null;
    
    try {
      final fileName = file.path.split('/').last;
      final ref = _storage.ref().child('evidence/$caseId/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload evidence: $e');
    }
  }

  /// Submits the report to Firestore and returns a map with caseId & secretKey.
  Future<Map<String, String>> submitReport({
    required String category,
    required String description,
    required String? optionalUrl,
    required File? evidenceFile,
    required String? selectedNgoId,
  }) async {
    try {
      final String caseId = _generateRandomString(6);
      final String secretKey = _generateRandomString(4);

      // 1. Upload evidence if exists
      String? evidenceUrl;
      if (evidenceFile != null) {
        evidenceUrl = await _uploadEvidence(evidenceFile, caseId);
      }

      // 2. Mock AI Hashing if URL provided
      String? blockchainHash;
      if (optionalUrl != null && optionalUrl.isNotEmpty) {
        blockchainHash = await generateBlockchainHash(optionalUrl);
      }

      // 3. AI Analysis
      final aiResult = await _mockAI.analyzeCase(description, optionalUrl ?? '');

      // 4. Determine invited NGOs
      List<String> invitedNgoIds = [];
      if (selectedNgoId != null) {
        invitedNgoIds.add(selectedNgoId);
      } else {
        invitedNgoIds.addAll(aiResult.recommendedNgos);
      }
      
      // ALWAYS route to the admin NGO id so the dashboard can see the cases during the hackathon
      if (!invitedNgoIds.contains('admin_ngo_id')) {
        invitedNgoIds.add('admin_ngo_id');
      }

      // 5. Generate random AI threat score
      final aiThreatScore = 70 + _random.nextInt(30); // 70-99

      // 6. Save to Firestore
      final creatorUid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_uid';

      await _firestore.collection('cases').doc(caseId).set({
        'caseId': caseId,
        'secretKey': secretKey,
        'category': category,
        'description': description,
        'evidenceUrl': evidenceUrl,
        'optionalUrl': optionalUrl,
        'blockchainHash': blockchainHash,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'aiThreatScore': aiThreatScore,
        'severity': aiResult.severity,
        'aiSummary': aiResult.summary,
        'invitedNgoIds': invitedNgoIds,
        'assignedNgoId': null,
        'isIdentityRevealed': false,
        'creatorId': creatorUid,
      });

      return {
        'caseId': caseId,
        'secretKey': secretKey,
      };
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
