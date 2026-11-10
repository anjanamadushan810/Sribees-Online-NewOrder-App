import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Secure Storage Service for Auth Tokens and Current Branch State
/// Includes resilient in-memory caching and SharedPreferences fallback
/// to prevent session drops caused by Android Keystore resets.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // In-memory cache for instant zero-latency retrieval and crash resilience
  String? _memAccessToken;
  String? _memRefreshToken;
  String? _memUserData;
  String? _memBranchId;
  String? _memBranchName;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  // Access Token
  Future<void> saveAccessToken(String token) async {
    _memAccessToken = token;
    try {
      await _storage.write(key: AppConstants.keyAccessToken, value: token);
    } catch (_) {
      // Fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAccessToken, token);
    }
  }

  Future<String?> getAccessToken() async {
    if (_memAccessToken != null && _memAccessToken!.isNotEmpty) {
      return _memAccessToken;
    }
    try {
      final val = await _storage.read(key: AppConstants.keyAccessToken);
      if (val != null && val.isNotEmpty) {
        _memAccessToken = val;
        return val;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(AppConstants.keyAccessToken);
      if (val != null && val.isNotEmpty) {
        _memAccessToken = val;
        return val;
      }
    } catch (_) {}

    return null;
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    _memRefreshToken = token;
    try {
      await _storage.write(key: AppConstants.keyRefreshToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyRefreshToken, token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memRefreshToken != null && _memRefreshToken!.isNotEmpty) {
      return _memRefreshToken;
    }
    try {
      final val = await _storage.read(key: AppConstants.keyRefreshToken);
      if (val != null && val.isNotEmpty) {
        _memRefreshToken = val;
        return val;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(AppConstants.keyRefreshToken);
      if (val != null && val.isNotEmpty) {
        _memRefreshToken = val;
        return val;
      }
    } catch (_) {}

    return null;
  }

  // Selected Branch ID
  Future<void> saveSelectedBranchId(String? branchId) async {
    _memBranchId = branchId;
    try {
      if (branchId == null) {
        await _storage.delete(key: AppConstants.keySelectedBranchId);
      } else {
        await _storage.write(key: AppConstants.keySelectedBranchId, value: branchId);
      }
    } catch (_) {}
  }

  Future<String?> getSelectedBranchId() async {
    if (_memBranchId != null) return _memBranchId;
    try {
      final val = await _storage.read(key: AppConstants.keySelectedBranchId);
      _memBranchId = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  // Selected Branch Name
  Future<void> saveSelectedBranchName(String? name) async {
    _memBranchName = name;
    try {
      if (name == null) {
        await _storage.delete(key: AppConstants.keySelectedBranchName);
      } else {
        await _storage.write(key: AppConstants.keySelectedBranchName, value: name);
      }
    } catch (_) {}
  }

  Future<String?> getSelectedBranchName() async {
    if (_memBranchName != null) return _memBranchName;
    try {
      final val = await _storage.read(key: AppConstants.keySelectedBranchName);
      _memBranchName = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  // Cached User Data JSON
  Future<void> saveUserData(String jsonStr) async {
    _memUserData = jsonStr;
    try {
      await _storage.write(key: AppConstants.keyUserData, value: jsonStr);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserData, jsonStr);
    }
  }

  Future<String?> getUserData() async {
    if (_memUserData != null && _memUserData!.isNotEmpty) {
      return _memUserData;
    }
    try {
      final val = await _storage.read(key: AppConstants.keyUserData);
      if (val != null && val.isNotEmpty) {
        _memUserData = val;
        return val;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(AppConstants.keyUserData);
      if (val != null && val.isNotEmpty) {
        _memUserData = val;
        return val;
      }
    } catch (_) {}

    return null;
  }

  // Clear all storage on logout
  Future<void> clearAll() async {
    _memAccessToken = null;
    _memRefreshToken = null;
    _memUserData = null;
    _memBranchId = null;
    _memBranchName = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAccessToken);
      await prefs.remove(AppConstants.keyRefreshToken);
      await prefs.remove(AppConstants.keyUserData);
      await prefs.remove(AppConstants.keySelectedBranchId);
      await prefs.remove(AppConstants.keySelectedBranchName);
    } catch (_) {}
  }
}
