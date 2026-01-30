import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/api/api_config.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';

class TeacherShareInvitePage extends StatefulWidget {
  const TeacherShareInvitePage({Key? key}) : super(key: key);

  @override
  State<TeacherShareInvitePage> createState() => _TeacherShareInvitePageState();
}

class _TeacherShareInvitePageState extends State<TeacherShareInvitePage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  String _inviteCode = '...';

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/invites/code',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final code = data['code']?.toString();
        if (code != null && code.isNotEmpty) {
          setState(() {
            _inviteCode = code;
          });
        }
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load invite code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _inviteLink() {
    final base = socketBaseUrl();
    return '$base/invite?code=$_inviteCode';
  }

  String _inviteMessage() {
    return 'Join my class on HomeTutor. Use invite code: $_inviteCode';
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openUrl(String url, String errorMessage) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _shareWhatsApp() async {
    final message = _inviteMessage();
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    await _openUrl(url, 'Unable to open WhatsApp.');
  }

  Future<void> _shareEmail() async {
    final message = _inviteMessage();
    final subject = Uri.encodeComponent('HomeTutor invite');
    final body = Uri.encodeComponent(message);
    await _copyText(message, 'Invite message copied.');
    await _openUrl('mailto:?subject=$subject&body=$body', 'Unable to open email.');
  }

  Future<void> _shareWithStudents() async {
    await _copyText(_inviteMessage(), 'Invite message copied. Choose a share option.');
  }

  @override
  Widget build(BuildContext context) {
    final inviteLink = _inviteLink();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.teacherHome,
            (route) => false,
          ),
        ),
        title: const Text(
          'Share Invite',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite code',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  )
                else
                  Text(
                    _inviteCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Copy invite code',
            height: 46,
            onPressed: _inviteCode == '...'
                ? null
                : () => _copyText(_inviteCode, 'Invite code copied.'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Share with students',
            height: 46,
            onPressed: _inviteCode == '...' ? null : _shareWithStudents,
          ),
          const SizedBox(height: 20),
          const Text(
            'Share options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _ShareOption(
            label: 'WhatsApp',
            icon: Icons.message,
            onTap: _inviteCode == '...' ? null : _shareWhatsApp,
          ),
          const SizedBox(height: 10),
          _ShareOption(
            label: 'Email',
            icon: Icons.email,
            onTap: _inviteCode == '...' ? null : _shareEmail,
          ),
          const SizedBox(height: 10),
          _ShareOption(
            label: 'Copy link',
            icon: Icons.link,
            onTap: _inviteCode == '...'
                ? null
                : () => _copyText(inviteLink, 'Invite link copied.'),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ShareOption({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.categoryBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

