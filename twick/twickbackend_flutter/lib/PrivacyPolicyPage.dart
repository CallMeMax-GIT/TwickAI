import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text(
          'Privacy Policy',
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
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.purple[600],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: January 2026',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Content Sections
            _PolicySection(
              title: '1. Information We Collect',
              content: '''
We collect information that you provide directly to us, including:
• Account information (name, email, profile picture)
• Task and reminder data
• Notification preferences
• Device information for app functionality
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '2. How We Use Your Information',
              content: '''
We use the information we collect to:
• Provide and maintain our services
• Sync your data across devices
• Send you notifications and reminders
• Improve our app and user experience
• Ensure security and prevent fraud
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '3. Data Storage and Security',
              content: '''
• Your data is stored securely on our servers using industry-standard encryption
• We use secure authentication methods to protect your account
• Local data is stored on your device using encrypted storage
• We regularly update our security measures to protect your information
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '4. Data Sharing',
              content: '''
We do not sell, trade, or rent your personal information to third parties. We may share your information only:
• With your explicit consent
• To comply with legal obligations
• To protect our rights and safety
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '5. Your Rights',
              content: '''
You have the right to:
• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Export your data
• Opt-out of certain data processing
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '6. Third-Party Services',
              content: '''
Our app uses third-party services that may collect information:
• Google Sign-In for authentication
• Apple Sign-In for authentication
• Serverpod Cloud for backend services
These services have their own privacy policies.
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '7. Children\'s Privacy',
              content: '''
Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '8. Changes to This Policy',
              content: '''
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.
              ''',
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '9. Contact Us',
              content: '''
If you have any questions about this Privacy Policy, please contact us at:
• Email: kevinphilip903@gmail.com
• Through the Help & Support section in the app
              ''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({
    required this.title,
    required this.content,
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
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
