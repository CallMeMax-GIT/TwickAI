import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'kevinphilip903@gmail.com',
      query: 'subject=Support Request',
    );
    if (await url_launcher.canLaunchUrl(emailUri)) {
      await url_launcher.launchUrl(emailUri);
    } else {
      // Show snackbar if email can't be launched
      debugPrint('Could not launch email: $emailUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'re here to help!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // FAQ Section
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _FAQItem(
              question: 'How do I create a task?',
              answer: 'Tap the blue "+" button on the home screen, then use voice or text input to create your task. You can say things like "Remind me to call John at 3 PM" or "Create a task for tomorrow at 9 AM".',
            ),
            const SizedBox(height: 12),
            
            _FAQItem(
              question: 'How do recurring tasks work?',
              answer: 'When creating a task, you can set it to repeat at intervals (minutes, hours, daily, or weekly). The app will automatically reschedule the task after each occurrence.',
            ),
            const SizedBox(height: 12),
            
            _FAQItem(
              question: 'Can I use the app offline?',
              answer: 'Yes! The app works fully offline. All your tasks are stored locally. When you\'re back online, your data will automatically sync with the server.',
            ),
            const SizedBox(height: 12),
            
            _FAQItem(
              question: 'How do I sync my data across devices?',
              answer: 'Sign in with the same account on all your devices. Your tasks, categories, and settings will automatically sync when you\'re online.',
            ),
            const SizedBox(height: 12),
            
            _FAQItem(
              question: 'How do I change notification settings?',
              answer: 'Go to the home screen and tap the notification icon in the top right. You can enable/disable notifications and set up sleep mode to avoid notifications during specific hours.',
            ),
            const SizedBox(height: 12),
            
            _FAQItem(
              question: 'Can I delete my account?',
              answer: 'Yes, you can delete your account from the Profile page. This will permanently delete all your data from our servers. Make sure to export any important data before deleting.',
            ),
            const SizedBox(height: 32),
            
            const SizedBox(height: 32),
            
            // Contact Section
            Text(
              'CONTACT SUPPORT',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _ContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'kevinphilip903@gmail.com',
              color: Colors.blue,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 12),
            
            _ContactCard(
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              color: Colors.red,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 32),
            
            // Tips Section
            Text(
              'QUICK TIPS',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            _TipCard(
              icon: Icons.mic,
              tip: 'Use voice input for faster task creation',
            ),
            const SizedBox(height: 12),
            
            _TipCard(
              icon: Icons.category,
              tip: 'Organize tasks with categories',
            ),
            const SizedBox(height: 12),
            
            _TipCard(
              icon: Icons.priority_high,
              tip: 'Set priorities to focus on important tasks',
            ),
            const SizedBox(height: 12),
            
            _TipCard(
              icon: Icons.sync,
              tip: 'Keep the app online to sync across devices',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _TipCard({
    required this.icon,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
