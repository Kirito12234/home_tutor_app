import 'package:http/http.dart' as http;

import '../../api/api_client.dart';
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
    final paths = <String>[
      '/api/v1/users/me',
      '/api/v1/auth/me',
      '/api/v1/me',
    ];

    Map<String, dynamic>? fallbackUser;
    for (final path in paths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final user = _extractUserPayload(response);
        if (user != null) {
          if (fallbackUser == null) {
            fallbackUser = user;
          }
          final avatar = _extractAvatarUrl(user);
          if (avatar != null && avatar.trim().isNotEmpty) {
            return user;
          }
        }
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        rethrow;
      }
    }
    return fallbackUser;
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
    final avatar = _extractAvatarUrl(payload);
    if (avatar != null && avatar.trim().isNotEmpty) {
      await HiveService.setCurrentUserAvatarUrl(avatar);
    }
  }

  Future<String?> uploadAvatar(SelectedFile file) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      throw HttpException(401, 'Please log in to update your photo.');
    }

    final paths = <String>[
      '/api/v1/users/me/image',
      '/api/v1/auth/me/image',
      '/api/v1/auth/image',
      '/api/v1/users/me/avatar',
      '/api/v1/auth/me/avatar',
      '/api/v1/auth/avatar',
    ];
    final fields = <String>['image', 'file', 'profile', 'avatar'];
    Map<String, dynamic>? response;
    HttpException? lastError;

    for (final path in paths) {
      for (final field in fields) {
        try {
          final upload = await _buildMultipartFile(file, field);
          response = await _apiClient.postMultipart(
            path,
            token: token,
            files: [upload],
          );
          break;
        } on HttpException catch (err) {
          lastError = err;
          if (err.statusCode == 404 || err.statusCode == 405) {
            continue;
          }
        }
      }
      if (response != null) {
        break;
      }
    }

    if (response == null && lastError != null) {
      throw lastError;
    }
    if (response == null) {
      throw HttpException(500, 'Unable to upload profile photo.');
    }

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

    final paths = <String>[
      '/api/v1/users/me/image',
      '/api/v1/auth/me/image',
      '/api/v1/auth/image',
      '/api/v1/users/me/avatar',
      '/api/v1/auth/me/avatar',
      '/api/v1/auth/avatar',
    ];
    HttpException? lastError;
    var deleted = false;
    for (final path in paths) {
      try {
        await _apiClient.deleteJson(path, token: token);
        deleted = true;
        break;
      } on HttpException catch (err) {
        lastError = err;
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        break;
      }
    }
    if (!deleted) {
      if (lastError != null) {
        throw lastError;
      }
      throw HttpException(500, 'Unable to remove profile photo.');
    }
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
    if (data is Map<String, dynamic>) {
      final nestedUser = _extractUserPayload(data);
      if (nestedUser != null && !identical(nestedUser, data)) {
        final nestedAvatar = _extractAvatarUrl(nestedUser);
        if (nestedAvatar != null && nestedAvatar.trim().isNotEmpty) {
          return nestedAvatar;
        }
      }
      final avatar = data['imageUrl'] ??
          data['image'] ??
          data['photoUrl'] ??
          data['profileImage'] ??
          data['profilePhoto'] ??
          data['avatarUrl'] ??
          data['avatar'] ??
          data['url'];
      return avatar?.toString();
    }
    if (data is String) {
      return data;
    }
    return null;
  }

  Map<String, dynamic>? _extractUserPayload(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['user'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    return null;
  }
}


