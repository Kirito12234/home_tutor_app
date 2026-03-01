import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';

class TeacherPayoutSettingsPage extends StatefulWidget {
  const TeacherPayoutSettingsPage({super.key});

  @override
  State<TeacherPayoutSettingsPage> createState() => _TeacherPayoutSettingsPageState();
}

class _TeacherPayoutSettingsPageState extends State<TeacherPayoutSettingsPage> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _courseCount = 0;
  final List<_CourseRow> _recentCourses = <_CourseRow>[];
  final List<_PaymentRequest> _requests = <_PaymentRequest>[];
  final Map<_PaymentMethod, _PaymentProof> _proofByMethod =
      <_PaymentMethod, _PaymentProof>{};
  final Map<_PaymentMethod, String> _settingIdByMethod =
      <_PaymentMethod, String>{};
  final Map<_PaymentMethod, SelectedFile> _pendingQrByMethod =
      <_PaymentMethod, SelectedFile>{};

  _PaymentMethod _selectedMethod = _PaymentMethod.khalti;
  SelectedFile? _selectedQrFile;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadCachedPendingQr();
    _loadCachedProofs();
    _loadPayoutData();
  }

  void _loadCachedPendingQr() {
    final raw = HiveService.getTeacherPayoutPendingQrCache();
    if (raw.isEmpty) {
      return;
    }
    for (final entry in raw.entries) {
      final method = _PaymentMethodX.tryParse(entry.key);
      final value = entry.value;
      if (method == null || value is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(value);
      final path = map['path']?.toString() ?? '';
      if (path.trim().isEmpty) {
        continue;
      }
      _pendingQrByMethod[method] = SelectedFile(
        name: map['name']?.toString() ?? path.split(Platform.pathSeparator).last,
        path: path,
        extension: map['extension']?.toString(),
        mimeType: map['mimeType']?.toString(),
      );
    }
    _selectedQrFile = _pendingQrByMethod[_selectedMethod];
  }

  Future<void> _persistPendingQrCache() async {
    final map = <String, dynamic>{};
    for (final entry in _pendingQrByMethod.entries) {
      final path = entry.value.path;
      if (path == null || path.trim().isEmpty) {
        continue;
      }
      map[entry.key.apiValue] = <String, dynamic>{
        'name': entry.value.name,
        'path': path,
        'extension': entry.value.extension,
        'mimeType': entry.value.mimeType,
      };
    }
    await HiveService.setTeacherPayoutPendingQrCache(map);
  }

  void _loadCachedProofs() {
    final raw = HiveService.getTeacherPayoutProofCache();
    if (raw.isEmpty) {
      return;
    }
    final parsed = <_PaymentMethod, _PaymentProof>{};
    for (final entry in raw.entries) {
      final method = _PaymentMethodX.tryParse(entry.key);
      final value = entry.value;
      if (method == null || value is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(value);
      final url = _resolveAssetUrl(map['url']?.toString());
      if (url.isEmpty) {
        continue;
      }
      parsed[method] = _PaymentProof(
        fileName: map['fileName']?.toString() ?? method.uploadLabel,
        url: url,
      );
    }
    if (parsed.isNotEmpty) {
      _setStateIfMounted(() {
        _proofByMethod
          ..clear()
          ..addAll(parsed);
      });
    }
  }

  Future<void> _persistProofCache() async {
    final map = <String, dynamic>{};
    for (final entry in _proofByMethod.entries) {
      if (entry.value.url.trim().isEmpty) {
        continue;
      }
      map[entry.key.apiValue] = <String, dynamic>{
        'fileName': entry.value.fileName,
        'url': entry.value.url,
      };
    }
    await HiveService.setTeacherPayoutProofCache(map);
  }

  Future<void> _loadPayoutData() async {
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentName = HiveService.currentUserName;
      final query = (currentName != null && currentName.trim().isNotEmpty)
          ? '?instructor=${Uri.encodeComponent(currentName)}'
          : '';
      final response = await _apiClient.getJson(
        '/api/v1/courses$query',
        token: HiveService.authToken,
      );

      final data = response['data'];
      if (data is! List) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Unexpected response format.';
          _courseCount = 0;
          _recentCourses.clear();
        });
        return;
      }

      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(_CourseRow.fromJson)
          .toList();

      _setStateIfMounted(() {
        _courseCount = mapped.length;
        _recentCourses
          ..clear()
          ..addAll(mapped.take(5));
      });

      await _loadPaymentDataFromServer();
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load payouts data.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickQrFile() async {
    final selected = await Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => FilePickerScreen(
          title: 'Upload ${_selectedMethod.uploadLabel}',
          allowAny: false,
          allowPdf: false,
          allowImages: true,
          allowCamera: true,
        ),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    _setStateIfMounted(() {
      _selectedQrFile = selected;
      _pendingQrByMethod[_selectedMethod] = selected;
    });
    await _persistPendingQrCache();
  }

  Future<void> _loadPaymentDataFromServer() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      _setStateIfMounted(() {
        _proofByMethod.clear();
        _settingIdByMethod.clear();
        _requests.clear();
      });
      return;
    }
    final response = await _apiClient.getJson('/api/v1/payout-settings',
        token: token);
    final data = response['data'];
    if (data is! List) {
      return;
    }

    final parsedMethods = <_PaymentMethod, _PaymentProof>{};
    final settingIds = <_PaymentMethod, String>{};
    final parsedRequests = <_PaymentRequest>[];
    for (final row in data.whereType<Map>()) {
      final map = Map<String, dynamic>.from(row);
      final method = _PaymentMethodX.tryParse(map['method']?.toString());
      if (method == null) {
        continue;
      }

      final detailsRaw = map['details'];
      final details = detailsRaw is Map
          ? Map<String, dynamic>.from(detailsRaw)
          : <String, dynamic>{};

      final url = _resolveAssetUrl(
        details['qrImageUrl']?.toString() ??
            details['qrUrl']?.toString() ??
            details['imageUrl']?.toString() ??
            map['qrImageUrl']?.toString() ??
            map['imageUrl']?.toString(),
      );
      if (url.isEmpty) {
        continue;
      }

      final fileName = details['name']?.toString() ??
          map['name']?.toString() ??
          method.uploadLabel;
      parsedMethods[method] = _PaymentProof(
        fileName: fileName,
        url: url,
      );

      final settingId = map['_id']?.toString() ?? map['id']?.toString() ?? '';
      if (settingId.isNotEmpty) {
        settingIds[method] = settingId;
      }
      parsedRequests.add(
        _PaymentRequest(
          method: method.displayName,
          fileName: fileName,
          submittedAt: DateTime.tryParse(
                map['updatedAt']?.toString() ?? map['createdAt']?.toString() ?? '',
              ) ??
              DateTime.now(),
          status: 'Saved',
        ),
      );
    }

    _setStateIfMounted(() {
      _proofByMethod
        ..clear()
        ..addAll(parsedMethods);
      _settingIdByMethod
        ..clear()
        ..addAll(settingIds);
      _requests
        ..clear()
        ..addAll(parsedRequests);
    });
    await _persistProofCache();
  }

  String _resolveAssetUrl(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    if (_isLocalFilePath(raw)) {
      return raw;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = socketBaseUrl();
    if (raw.startsWith('/')) {
      return '$base$raw';
    }
    return '$base/$raw';
  }

  bool _isLocalFilePath(String value) {
    final lower = value.toLowerCase();
    return value.startsWith('/') ||
        lower.startsWith('file://') ||
        lower.contains(':\\') ||
        lower.startsWith(r'\\');
  }

  Future<http.MultipartFile> _buildMultipartFile(
    SelectedFile file,
    String fieldName,
  ) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        fieldName,
        file.bytes!,
        filename: file.name,
      );
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(fieldName, file.path!);
    }
    throw Exception('File data unavailable');
  }

  Future<void> _submitForReview() async {
    if (_selectedQrFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload ${_selectedMethod.uploadLabel} first.')),
      );
      return;
    }

    _setStateIfMounted(() {
      _isSubmitting = true;
    });

    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      _setStateIfMounted(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again.')),
        );
      }
      return;
    }

    try {
      final file = _selectedQrFile!;
      final upload = await _buildMultipartFile(file, 'qrCode');
      final uploadedResponse = await _apiClient.postMultipart(
        '/api/v1/payout-settings/upload-qr',
        token: token,
        files: [upload],
      );
      final uploadData = uploadedResponse['data'];
      final relativeOrAbsolute = uploadData is Map
          ? (uploadData['relativeUrl']?.toString() ??
              uploadData['url']?.toString() ??
              '')
          : '';
      final proofUrl = _resolveAssetUrl(relativeOrAbsolute);
      if (proofUrl.isEmpty) {
        throw Exception('Unable to upload QR image.');
      }

      final body = {
        'method': _selectedMethod.apiValue,
        'details': {
          'name': file.name,
          'qrImageUrl': relativeOrAbsolute,
        },
        'isDefault': true,
      };

      final settingId = _settingIdByMethod[_selectedMethod];
      final settingResponse = (settingId == null || settingId.isEmpty)
          ? await _apiClient.postJson(
              '/api/v1/payout-settings',
              token: token,
              body: body,
            )
          : await _apiClient.putJson(
              '/api/v1/payout-settings/$settingId',
              token: token,
              body: body,
            );
      final settingData = settingResponse['data'];
      final savedId = settingData is Map
          ? (settingData['_id']?.toString() ?? settingData['id']?.toString() ?? '')
          : '';

      _setStateIfMounted(() {
        _proofByMethod[_selectedMethod] = _PaymentProof(
          fileName: file.name,
          url: proofUrl,
        );
        _pendingQrByMethod.remove(_selectedMethod);
        if (savedId.isNotEmpty) {
          _settingIdByMethod[_selectedMethod] = savedId;
        }
        _requests.insert(
          0,
          _PaymentRequest(
            method: _selectedMethod.displayName,
            fileName: file.name,
            submittedAt: DateTime.now(),
            status: 'Saved',
          ),
        );
        _selectedQrFile = null;
      });
      await _persistPendingQrCache();
      await _persistProofCache();

      await _loadPaymentDataFromServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code saved. Students can now view it.')),
        );
      }
    } on HttpException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save QR code.')),
        );
      }
    } finally {
      _setStateIfMounted(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Widget _buildMethodChip(_PaymentMethod method) {
    final isActive = method == _selectedMethod;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
          _selectedQrFile = _pendingQrByMethod[method];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          method.displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.buttonText : AppColors.teacherPrimaryDark,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentVisual() {
    final proof = _proofByMethod[_selectedMethod];
    final selected = _selectedQrFile;
    final localImageBytes = selected?.bytes;
    final localPath = selected?.path;
    final localFilePath = localPath ?? '';
    final hasNewLocalImage = localImageBytes != null && localImageBytes.isNotEmpty;
    final hasNewLocalPath = localPath != null && localPath.trim().isNotEmpty;
    final hasServerImage = proof != null && proof.url.isNotEmpty;
    final hasAnyImage = hasNewLocalImage || hasNewLocalPath || hasServerImage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 210,
      height: 165,
      decoration: BoxDecoration(
        color: _selectedMethod.previewBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasNewLocalImage)
              Image.memory(
                localImageBytes,
                fit: BoxFit.cover,
              )
            else if (hasNewLocalPath)
              Image.file(
                File(localFilePath.replaceFirst('file://', '')),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _selectedMethod.previewBackground,
                ),
              )
            else if (hasServerImage)
              _isLocalFilePath(proof.url)
                  ? Image.file(
                      File(proof.url.replaceFirst('file://', '')),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _selectedMethod.previewBackground,
                      ),
                    )
                  : Image.network(
                      proof.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _selectedMethod.previewBackground,
                      ),
                    ),
            if (!hasAnyImage)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedMethod.previewIcon,
                        size: 36,
                        color: _selectedMethod.iconColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedMethod.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedMethod.uploadLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Teacher QR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teacherBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Payouts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayoutData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'COURSE CREATED',
                          value: _isLoading ? '...' : '$_courseCount',
                          subtitle: 'Active courses on your profile',
                          background: const Color(0xFFF3F5F8),
                          borderColor: AppColors.divider,
                          valueColor: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _SummaryCard(
                          title: 'PREMIUM PLAN',
                          value: 'NPR 600/month',
                          subtitle: 'Monthly billing',
                          background: Color(0xFFDDF4E7),
                          borderColor: Color(0xFF9ED8B8),
                          valueColor: AppColors.teacherPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'SELECT PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teacherPrimaryDark,
                        letterSpacing: 0.4,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: _PaymentMethod.values.map(_buildMethodChip).toList(),
                  ),
                  const SizedBox(height: 14),
                  Center(child: _buildPaymentVisual()),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickQrFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 18, color: AppColors.teacherMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedQrFile?.name ??
                                  _proofByMethod[_selectedMethod]?.fileName ??
                                  'Upload ${_selectedMethod.uploadLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.teacherPrimaryDark,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Browse',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19B77E),
                        foregroundColor: AppColors.buttonText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSubmitting ? 'Saving...' : 'Save QR for Students',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_requests.isEmpty)
                    const Text(
                      'No payment submissions yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.teacherMuted,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ..._requests.map(
                    (request) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.method} - ${request.status}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${request.fileName} - ${_formatDate(request.submittedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recently created',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  if (!_isLoading && _recentCourses.isEmpty)
                    const Text(
                      'No courses found.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.teacherMuted,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ..._recentCourses.map(
                    (course) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(course.createdAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            course.priceLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.background,
    required this.borderColor,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color background;
  final Color borderColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.teacherMuted,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaymentMethod {
  eSewa,
  khalti,
  imePay,
  bankTransfer;

  String get apiValue {
    switch (this) {
      case _PaymentMethod.eSewa:
        return 'esewa';
      case _PaymentMethod.khalti:
        return 'khalti';
      case _PaymentMethod.imePay:
        return 'imepay';
      case _PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  String get displayName {
    switch (this) {
      case _PaymentMethod.eSewa:
        return 'eSewa';
      case _PaymentMethod.khalti:
        return 'Khalti';
      case _PaymentMethod.imePay:
        return 'IME Pay';
      case _PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get uploadLabel {
    switch (this) {
      case _PaymentMethod.eSewa:
        return 'eSewa QR';
      case _PaymentMethod.khalti:
        return 'khalti QR';
      case _PaymentMethod.imePay:
        return 'IME Pay QR';
      case _PaymentMethod.bankTransfer:
        return 'bank receipt';
    }
  }

  IconData get previewIcon {
    switch (this) {
      case _PaymentMethod.eSewa:
        return Icons.qr_code_2;
      case _PaymentMethod.khalti:
        return Icons.qr_code;
      case _PaymentMethod.imePay:
        return Icons.account_balance_wallet;
      case _PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  Color get previewBackground {
    switch (this) {
      case _PaymentMethod.eSewa:
        return const Color(0xFF1D7E5B);
      case _PaymentMethod.khalti:
        return const Color(0xFF0B1638);
      case _PaymentMethod.imePay:
        return const Color(0xFF1A3F8B);
      case _PaymentMethod.bankTransfer:
        return const Color(0xFF2B4B66);
    }
  }

  Color get iconColor {
    switch (this) {
      case _PaymentMethod.eSewa:
        return const Color(0xFF1D7E5B);
      case _PaymentMethod.khalti:
        return const Color(0xFF5D3FD3);
      case _PaymentMethod.imePay:
        return const Color(0xFF1A3F8B);
      case _PaymentMethod.bankTransfer:
        return const Color(0xFF2B4B66);
    }
  }
}

class _CourseRow {
  const _CourseRow({
    required this.title,
    required this.createdAt,
    required this.priceLabel,
  });

  final String title;
  final DateTime createdAt;
  final String priceLabel;

  static _CourseRow fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final formattedPrice = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return _CourseRow(
      title: json['title']?.toString() ?? 'Untitled course',
      createdAt: created,
      priceLabel: 'Rs $formattedPrice',
    );
  }
}

class _PaymentRequest {
  const _PaymentRequest({
    required this.method,
    required this.fileName,
    required this.submittedAt,
    required this.status,
  });

  final String method;
  final String fileName;
  final DateTime submittedAt;
  final String status;
}

class _PaymentProof {
  const _PaymentProof({
    required this.fileName,
    required this.url,
  });

  final String fileName;
  final String url;
}

extension _PaymentMethodX on _PaymentMethod {
  static _PaymentMethod? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'esewa':
      case 'e-sewa':
        return _PaymentMethod.eSewa;
      case 'khalti':
        return _PaymentMethod.khalti;
      case 'ime':
      case 'imepay':
      case 'ime_pay':
      case 'ime pay':
        return _PaymentMethod.imePay;
      case 'bank':
      case 'banktransfer':
      case 'bank_transfer':
      case 'bank transfer':
        return _PaymentMethod.bankTransfer;
      default:
        return null;
    }
  }
}


