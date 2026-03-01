import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../mobile/chat_screen.dart';
import 'widgets/case_details_dialog.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  Future<void> _acceptCase(String caseId, String ngoId, String ngoName) async {
    try {
      await _firestore.collection('cases').doc(caseId).update({
        'status': 'Active',
        'assignedNgoId': ngoId,
      });

      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(caseId: caseId, ngoName: ngoName),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting case: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // For mock AI logic, we assume currentUser.uid acts like 'ngo_X' if we want to test matching, 
    // but we'll query by 'admin_ngo_id' for this specific test case as requested by user
    final ngoId = 'admin_ngo_id'; 
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.lightBlue[900],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Talk Safe NGO',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.white),
                  title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                  selected: _selectedIndex == 0,
                  selectedTileColor: Colors.lightBlue[800],
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.white70),
                  title: const Text('Active Cases (Chats)', style: TextStyle(color: Colors.white70)),
                  selected: _selectedIndex == 1,
                  selectedTileColor: Colors.lightBlue[800],
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
                const Spacer(),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Logout', style: TextStyle(color: Colors.white70)),
                  onTap: () => authService.logout(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(32.0),
              child: _selectedIndex == 0 
                  ? _buildIncomingCases(currentUser.name, ngoId)
                  : _buildActiveCases(currentUser.name, ngoId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCases(String ngoName, String ngoId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incoming AI-Assigned Reports',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Victims have reported these cases and AI or the Victim has routed them to your NGO.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        
        // Firestore Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Since we don't have a composite index set up yet (status + invitedNgoIds + timestamp),
            // we query a simple index (by timestamp) and filter locally for this hackathon.
            stream: _firestore
                .collection('cases')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.lightBlue));
              }

              // Local Filter for Pending + Invited to this NGO
              final allCases = snapshot.data?.docs ?? [];
              final cases = allCases.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                final invitedNgoIds = List<String>.from(data['invitedNgoIds'] ?? []);
                
                // The hardcoded admin user ID is what we want ALL AI queries to map to
                return status == 'Pending' && invitedNgoIds.contains(ngoId);
              }).toList();

              if (cases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No incoming cases', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final doc = cases[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCaseCard(doc.id, data, ngoName, ngoId);
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildActiveCases(String ngoName, String ngoId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Cases (Chats)',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'These are the cases you have accepted.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('cases')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.lightBlue));
              }

              final allCases = snapshot.data?.docs ?? [];
              final cases = allCases.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                final assignedNgoId = data['assignedNgoId'] as String?;
                
                return status == 'Active' && assignedNgoId == ngoId;
              }).toList();

              if (cases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No active chats', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final doc = cases[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildActiveCaseRow(doc.id, data, ngoName);
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildActiveCaseRow(String id, Map<String, dynamic> data, String ngoName) {
    final timestamp = data['timestamp'] as Timestamp?;
    final timeString = timestamp != null 
        ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate()) 
        : 'Unknown time';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Colors.lightBlue,
          child: Icon(Icons.forum, color: Colors.white),
        ),
        title: Text('Case ID: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Opened on $timeString'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CaseDetailsDialog(
                    caseId: id,
                    data: data,
                    onChat: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(caseId: id, ngoName: ngoName),
                      ));
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(caseId: id, ngoName: ngoName),
                ));
              },
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(String id, Map<String, dynamic> data, String ngoName, String ngoId) {
    final severity = data['severity'] ?? 'Medium';
    final isHigh = severity == 'High';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeString = timestamp != null 
        ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate()) 
        : 'Just now';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isHigh ? Colors.red.shade200 : Colors.orange.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isHigh ? Colors.red[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isHigh ? Icons.warning : Icons.info, 
                       color: isHigh ? Colors.red : Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      color: isHigh ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Case ID: $id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    data['aiSummary'] ?? 'No summary available.',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text('Received: $timeString', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            
            // Action
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _acceptCase(id, ngoId, ngoName),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept Case'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CaseDetailsDialog(
                        caseId: id,
                        data: data,
                        onAccept: () => _acceptCase(id, ngoId, ngoName),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
