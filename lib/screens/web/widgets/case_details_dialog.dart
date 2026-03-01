import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CaseDetailsDialog extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> data;
  final VoidCallback? onAccept;
  final VoidCallback? onChat;

  const CaseDetailsDialog({
    super.key,
    required this.caseId,
    required this.data,
    this.onAccept,
    this.onChat,
  });

  Future<Map<String, dynamic>?> _fetchVictimDetails(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching victim details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final severity = data['severity'] ?? 'Medium';
    final isHigh = severity == 'High';
    final status = data['status'] ?? 'Pending';
    final isIdentityRevealed = data['isIdentityRevealed'] ?? false;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeString = timestamp != null
        ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate())
        : 'Unknown time';
    
    final evidenceUrl = data['evidenceUrl'] as String?;
    final optionalUrl = data['optionalUrl'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.lightBlue[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Case Details', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('ID: $caseId | Submitted: $timeString', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            
            // Body scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Analysis Section
                    _buildSectionHeader(Icons.psychology, 'AI Analysis & Threat Assessment'),
                    Card(
                      elevation: 0,
                      color: isHigh ? Colors.red.shade50 : Colors.orange.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isHigh ? Colors.red.shade200 : Colors.orange.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(isHigh ? Icons.warning : Icons.info, color: isHigh ? Colors.red : Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SEVERITY: ${severity.toUpperCase()}',
                                      style: TextStyle(color: isHigh ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Threat Score: ${data['aiThreatScore'] ?? 'N/A'}/100',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('AI Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(data['aiSummary'] ?? 'No summary available.', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Victim Details Section
                    _buildSectionHeader(Icons.person, 'Victim Information'),
                    if (isIdentityRevealed && data['creatorId'] != null)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchVictimDetails(data['creatorId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final victim = snapshot.data;
                          if (victim == null) {
                            return const Text('Victim has revealed identity, but account data is missing.');
                          }
                          return Card(
                            elevation: 0,
                            color: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(victim['name'] ?? 'Unknown Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(victim['email'] ?? 'No Email', style: TextStyle(color: Colors.grey[700])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield, color: Colors.green, size: 30),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Victim has chosen to remain anonymous. Their identity is protected globally.',
                                style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Report Content Section
                    _buildSectionHeader(Icons.description, 'Report Content'),
                    Text('Category', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(data['category'] ?? 'N/A', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    Text('Victim Description', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    if (optionalUrl != null && optionalUrl.isNotEmpty) ...[
                      Text('Social Media Link', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SelectableText(optionalUrl, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text('Blockchain Hash: ${data['blockchainHash'] ?? 'Pending'}', style: TextStyle(color: Colors.purple[700], fontFamily: 'monospace', fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Evidence Section
                    _buildSectionHeader(Icons.attach_file, 'Evidence'),
                    if (evidenceUrl != null && evidenceUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          evidenceUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                            );
                          },
                        ),
                      )
                    else
                      const Text('No image/screenshot attached by victim.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  if (status == 'Pending' && onAccept != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAccept!();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Accept Case'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    )
                  else if (status == 'Active' && onChat != null)
                     ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onChat!();
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Open Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightBlue, size: 28),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
