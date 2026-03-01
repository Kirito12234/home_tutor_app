import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../notifications/domain/entities/message_notification.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isOpeningSupportChat = false;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openSupportChat() async {
    if (_isOpeningSupportChat) {
      return;
    }
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      _showSnack(context, 'Please log in first.');
      return;
    }

    setState(() {
      _isOpeningSupportChat = true;
    });

    try {
      final response = await _apiClient.postJson(
        '/api/v1/support/chat-thread',
        token: token,
        body: {
          'message': 'Need support assistance.',
        },
      );
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid support chat response');
      }
      final threadId = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      if (threadId.isEmpty) {
        throw Exception('Support chat thread not found');
      }
      final threadStatus = data['status']?.toString().toLowerCase() ?? 'pending';
      final participantName = data['otherParticipantName']?.toString();
      if (mounted && threadStatus == 'pending') {
        _showSnack(context, 'Support chat sent. Waiting for admin approval.');
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.messageThread,
        arguments: MessageNotification(
          id: threadId,
          name: (participantName == null || participantName.trim().isEmpty)
              ? 'Admin Support'
              : participantName,
          isOnline: false,
          time: 'Now',
          message: data['lastMessageText']?.toString() ?? '',
        ),
      );
    } on HttpException catch (err) {
      _showSnack(context, err.message);
    } catch (_) {
      _showSnack(context, 'Unable to open support chat.');
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSupportChat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I join a live session?',
        'answer': 'Open a course, tap Join live session, and confirm.',
      },
      {
        'question': 'How can I message my mentor?',
        'answer': 'Open the course, go to Mentor, and tap Message.',
      },
      {
        'question': 'How do I reset my password?',
        'answer': 'Go to Settings & Privacy and select Change password.',
      },
      {
        'question': 'How do I download lessons?',
        'answer': 'Open a lesson video and tap Download.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                label: 'Contact support',
                onTap: () => _showSnack(context, 'Support contacted'),
              ),
              _ActionChip(
                label: 'Report a bug',
                onTap: () => _showSnack(context, 'Bug report opened'),
              ),
              _ActionChip(
                label: 'Request a course',
                onTap: () => _showSnack(context, 'Course request sent'),
              ),
              _ActionChip(
                label: 'Community guidelines',
                onTap: () => _showSnack(context, 'Opening guidelines'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'FAQ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 10),
          ...faqs.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                title: Text(
                  item['question']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item['answer']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.categoryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.headset_mic, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Need more help? We respond within 24 hours.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isOpeningSupportChat ? null : _openSupportChat,
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}

