import 'package:flutter/material.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Stay Safe Online',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the cards below for simple rules to protect your identity and mental peace.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          _buildInteractiveCard(
            context,
            icon: Icons.vpn_key_off,
            color: Colors.red,
            title: 'DON\'T share passwords',
            shortDesc: 'Never give your passwords to anyone, even "friends".',
            fullDesc: 'Scammers or malicious actors can use your password to steal your identity, access private photos, and lock you out of your own life.',
            isDo: false,
          ),
          _buildInteractiveCard(
            context,
            icon: Icons.lock_person,
            color: Colors.green,
            title: 'DO use 2FA',
            shortDesc: 'Turn on Two-Factor Authentication on all apps.',
            fullDesc: 'Even if someone gets your password, they cannot log in without the special code sent to your phone. It is your strongest shield against hacking.',
            isDo: true,
          ),
          _buildInteractiveCard(
            context,
            icon: Icons.camera_alt_outlined,
            color: Colors.red,
            title: 'DON\'T send intimate photos',
            shortDesc: 'If it\'s on the internet, it lives forever.',
            fullDesc: 'Intimate photos can be used for blackmail or image-based abuse. Never feel pressured to send them. You have the right to say NO.',
            isDo: false,
          ),
          _buildInteractiveCard(
            context,
            icon: Icons.block,
            color: Colors.green,
            title: 'DO block & report',
            shortDesc: 'Don\'t argue with trolls. Just block them.',
            fullDesc: 'If someone makes you uncomfortable, immediately press the Block and Report buttons. You do not owe anyone your time or attention.',
            isDo: true,
          ),
           _buildInteractiveCard(
            context,
            icon: Icons.location_off,
            color: Colors.red,
            title: 'DON\'T share live locations',
            shortDesc: 'Avoid posting where you are right now.',
            fullDesc: 'Stalkers can trace your exact routines if you tag your location in real-time. Post about empty locations only after you have left them.',
            isDo: false,
          ),
          _buildInteractiveCard(
            context,
            icon: Icons.diversity_1,
            color: Colors.green,
            title: 'DO ask for help',
            shortDesc: 'If you feel threatened, speak up immediately.',
            fullDesc: 'If you are experiencing online harassment, use our Report tab secretly. We will connect you to an NGO that can guide you. You are not alone.',
            isDo: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInteractiveCard(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String shortDesc,
    required String fullDesc,
    required bool isDo,
  }) {
    return _InteractiveSafetyCard(
      icon: icon,
      color: color,
      title: title,
      shortDesc: shortDesc,
      fullDesc: fullDesc,
      isDo: isDo,
    );
  }
}

class _InteractiveSafetyCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String shortDesc;
  final String fullDesc;
  final bool isDo;

  const _InteractiveSafetyCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.shortDesc,
    required this.fullDesc,
    required this.isDo,
  });

  @override
  State<_InteractiveSafetyCard> createState() => _InteractiveSafetyCardState();
}

class _InteractiveSafetyCardState extends State<_InteractiveSafetyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _expanded ? widget.color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded ? widget.color : Colors.grey.shade300,
            width: _expanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _expanded ? 0.2 : 0.05),
              blurRadius: _expanded ? 15 : 5,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.shortDesc,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                widget.fullDesc,
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
