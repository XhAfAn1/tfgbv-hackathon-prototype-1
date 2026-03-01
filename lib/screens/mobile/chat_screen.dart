import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String caseId;
  final String ngoName;

  const ChatScreen({
    super.key,
    required this.caseId,
    required this.ngoName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isIdentityRevealed = false;

  @override
  void initState() {
    super.initState();
    _fetchIdentityStatus();
  }

  Future<void> _fetchIdentityStatus() async {
    final doc = await _firestore.collection('cases').doc(widget.caseId).get();
    if (doc.exists && mounted) {
      setState(() {
        _isIdentityRevealed = doc.data()?['isIdentityRevealed'] ?? false;
      });
    }
  }

  Future<void> _toggleIdentity(bool value) async {
    setState(() => _isIdentityRevealed = value);
    await _firestore.collection('cases').doc(widget.caseId).update({
      'isIdentityRevealed': value,
    });
    
    // Add a system message stating the identity was revealed
    if (value) {
       final user = context.read<AuthService>().currentUser;
       _sendMessage(text: "System: ${user?.name} has revealed their identity.", isSystem: true);
    }
  }

  void _sendMessage({String? text, bool isSystem = false}) async {
    final msgText = text ?? _messageController.text.trim();
    if (msgText.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    _messageController.clear();

    await _firestore.collection('cases').doc(widget.caseId).collection('messages').add({
      'text': msgText,
      'senderId': isSystem ? 'system' : user.uid,
      'senderRole': isSystem ? 'system' : user.role,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;
    final isVictim = currentUser?.role == 'victim';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ngoName, style: const TextStyle(fontSize: 16)),
            Text('Case: ${widget.caseId}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Privacy Toggle (Only Victim sees this)
          if (isVictim)
            Container(
              color: _isIdentityRevealed ? Colors.red[50] : Colors.green[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isIdentityRevealed ? Icons.warning_amber : Icons.shield,
                        color: _isIdentityRevealed ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isIdentityRevealed ? 'Identity Revealed' : 'Anonymous Mode',
                        style: TextStyle(
                          color: _isIdentityRevealed ? Colors.red[900] : Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isIdentityRevealed,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      if (val) {
                        // Confirm before revealing
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reveal Identity?'),
                            content: const Text('The NGO will be able to see your real name and email. This action can be toggled back, but the NGO may have already seen it.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _toggleIdentity(true);
                                },
                                child: const Text('Reveal', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _toggleIdentity(false);
                      }
                    },
                  ),
                ],
              ),
            )
          else if (!_isIdentityRevealed)
             // NGO sees this if Victim is anonymous
             Container(
               color: Colors.grey[200],
               padding: const EdgeInsets.all(8),
               width: double.infinity,
               child: const Text(
                 'Victim is currently anonymous.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
               ),
             )
          else if (_isIdentityRevealed)
             // NGO sees this if Victim revealed identity
             Container(
               color: Colors.blue[50],
               padding: const EdgeInsets.all(8),
               width: double.infinity,
               child: const Text(
                 'Victim has revealed their identity. Check Case Details.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
               ),
             ),

          // Chat Messages View
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('cases')
                  .doc(widget.caseId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data!.docs;
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser?.uid;
                    final isSystem = msg['senderId'] == 'system';
                    
                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            msg['text'],
                            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.lightBlue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : null,
                            bottomLeft: !isMe ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.lightBlue),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
