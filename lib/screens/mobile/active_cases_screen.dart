import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';

class ActiveCasesScreen extends StatelessWidget {
  const ActiveCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your cases.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cases')
            .where('creatorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             // In case there is an index error from Firestore
            return Center(child: Text('Error loading cases. Details: ${snapshot.error}'));
          }

          // Remove nulls to satisfy the sort contract safely
          final cases = snapshot.data?.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && data.containsKey('timestamp') && data['timestamp'] != null;
          }).toList() ?? [];

          // Sort descending locally to avoid index error
          cases.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return bTime.compareTo(aTime);
          });

          if (cases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No cases found.', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final doc = cases[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final status = data['status'] ?? 'Pending';
              final isActive = status == 'Active';
              final timestamp = data['timestamp'] as Timestamp?;
              final timeString = timestamp != null 
                  ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate()) 
                  : 'Unknown time';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green[100] : Colors.orange[100],
                    child: Icon(
                      isActive ? Icons.forum : Icons.hourglass_empty,
                      color: isActive ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                  title: Text(
                    'Case ID: ${doc.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Category: ${data['category']}'),
                      Text('Submitted: $timeString'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: isActive ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
                  onTap: isActive
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                caseId: doc.id,
                                ngoName: 'Assigned NGO', // Real app would look up NGO name
                              ),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This case is still pending review.')),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
