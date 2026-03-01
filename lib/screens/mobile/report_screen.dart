import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/report_service.dart';
import 'widgets/case_success_dialog.dart';
import 'widgets/map_selection_widget.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  
  final _reportService = ReportService();
  final _picker = ImagePicker();

  String _selectedCategory = 'Cyber Stalking';
  final List<String> _categories = [
    'Cyber Stalking',
    'Image Abuse',
    'Online Harassment',
    'Identity Theft',
    'Defamation',
    'Other'
  ];

  File? _evidenceFile;
  String? _selectedNgoId;
  bool _isSubmitting = false;
  String _loadingMessage = 'Submitting...';

  @override
  void dispose() {
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _evidenceFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _loadingMessage = 'Analyzing Evidence...';
    });

    try {
      if (_urlController.text.isNotEmpty) {
        // Simulate progress updates for UI effect
        await Future.delayed(const Duration(seconds: 1));
        setState(() => _loadingMessage = 'Generating Blockchain Hash...');
      }

      final result = await _reportService.submitReport(
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        optionalUrl: _urlController.text.trim(),
        evidenceFile: _evidenceFile,
        selectedNgoId: _selectedNgoId,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          // Clear form
          _descriptionController.clear();
          _urlController.clear();
          _evidenceFile = null;
        });

        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CaseSuccessDialog(
            caseId: result['caseId']!,
            secretKey: result['secretKey']!,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.lightBlue),
            const SizedBox(height: 24),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Submit Anonymous Report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your safety is our priority. Your identity remains completely hidden.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Violence Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 24),

            // Description Box
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              validator: (value) => 
                  value == null || value.isEmpty ? 'Please describe what happened' : null,
              decoration: InputDecoration(
                labelText: 'What happened?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // URL Field
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Paste Social Media Link (Optional)',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Evidence Upload
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_evidenceFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_evidenceFile!, height: 120, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _evidenceFile = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ] else ...[
                    Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach Screenshot/Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlue,
                        elevation: 1,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // NGO Selection Map / List
            MapSelectionWidget(
              onNgoSelected: (ngoId) {
                setState(() => _selectedNgoId = ngoId);
              },
            ),
            const SizedBox(height: 48),

            // Submit Button
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text(
                'SUBMIT ANONYMOUS REPORT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
