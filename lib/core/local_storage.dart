import 'package:crisant_connect/core/storage_keys.dart';
import 'package:crisant_connect/features/authentication/models/refresh_token_response.dart';
import 'package:crisant_connect/features/authentication/models/verify_otp_response.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  /// ---------- SAVE BASIC AUTH DATA ----------
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userToken, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.refreshToken, token);
  }

  static Future<void> saveAuthSession(VerifyOtpResponse response) async {
    await _saveSessionData(
      token: response.token,
      refreshToken: response.refreshToken,
      user: response.user,
    );
  }

  static Future<void> saveRefreshSession(RefreshTokenResponse response) async {
    await _saveSessionData(
      token: response.token,
      refreshToken: response.refreshToken,
      user: response.user,
    );
  }

  static Future<void> _saveSessionData({
    required String token,
    required String refreshToken,
    required AuthUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userToken, token);
    await prefs.setString(StorageKeys.refreshToken, refreshToken);
    await prefs.setInt(StorageKeys.userId, user.id);
    await prefs.setString(StorageKeys.userName, user.fullName);
    await prefs.setString(StorageKeys.userMobileNumber, user.mobileNumber);
    await prefs.setString(StorageKeys.userRole, user.role);
    if (user.approverId != null) {
      await prefs.setInt(StorageKeys.approverId, user.approverId!);
    } else {
      await prefs.remove(StorageKeys.approverId);
    }
    await prefs.setBool(StorageKeys.leadsAccess, user.leadsAccess);
  }

  ///------------GET DATA------------------////
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.userToken) ?? '';
  }

  static Future<String> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.refreshToken) ?? '';
  }

  /// ---------- CLEAR (preserves FCM token) ----------
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Preserve the FCM token across logouts — it's device-level, not session-level
    final fcmToken = prefs.getString(StorageKeys.fcmToken);
    await prefs.clear();
    if (fcmToken != null) {
      await prefs.setString(StorageKeys.fcmToken, fcmToken);
    }
  }

  /// ---------- SAVE USER NAME ----------
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userName, name);
  }

  static Future<void> saveUserProfile({
    required String fullName,
    required String mobileNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userName, fullName);
    await prefs.setString(StorageKeys.userMobileNumber, mobileNumber);
  }

  /// ---------- GET USER NAME ----------
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.userName) ?? '';
  }

  // /// ---------- FCM TOKEN HELPERS ----------
  // static Future<void> saveFcmToken(String token) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(StorageKeys.fcmToken, token);
  // }

  // static Future<String?> getFcmToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString(StorageKeys.fcmToken);
  // }

  // static Future<void> removeFcmToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(StorageKeys.fcmToken);
  // }
}
