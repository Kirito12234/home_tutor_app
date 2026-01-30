import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../hive/hive_service.dart';
import '../../widgets/file_picker_screen.dart';

class UserProfileService {
  UserProfileService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    final response = await _apiClient.getJson(
      '/api/v1/users/me',
      token: token,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    return null;
  }

  Future<void> refreshUserCache() async {
    final payload = await fetchCurrentUser();
    if (payload == null) {
      return;
    }
    final name = payload['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      await HiveService.setCurrentUserName(name);
    }
    if (payload.containsKey('avatarUrl')) {
      final avatar = payload['avatarUrl']?.toString();
      if (avatar == null || avatar.trim().isEmpty) {
        await HiveService.setCurrentUserAvatarUrl(null);
      } else {
        await HiveService.setCurrentUserAvatarUrl(avatar);
      }
    }
  }

  Future<String?> uploadAvatar(SelectedFile file) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      throw HttpException(401, 'Please log in to update your photo.');
    }

    final upload = await _buildMultipartFile(file, 'avatar');
    final response = await _apiClient.postMultipart(
      '/api/v1/users/me/avatar',
      token: token,
      files: [upload],
    );

    final avatarUrl = _extractAvatarUrl(response['data']) ??
        _extractAvatarUrl(response);
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      await HiveService.setCurrentUserAvatarUrl(avatarUrl);
      return avatarUrl;
    }

    await refreshUserCache();
    return HiveService.currentUserAvatarUrl;
  }

  Future<void> deleteAvatar() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      throw HttpException(401, 'Please log in to remove your photo.');
    }

    await _apiClient.deleteJson(
      '/api/v1/users/me/avatar',
      token: token,
    );
    await HiveService.setCurrentUserAvatarUrl(null);
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
    if (file.path != null) {
      return http.MultipartFile.fromPath(fieldName, file.path!);
    }
    throw Exception('File data not available.');
  }

  String? _extractAvatarUrl(Object? data) {
    if (data is Map) {
      final avatar = data['avatarUrl'] ?? data['url'] ?? data['imageUrl'];
      return avatar?.toString();
    }
    if (data is String) {
      return data;
    }
    return null;
  }
}
