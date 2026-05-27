import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/models/logout_response.dart';
import 'package:crisant_connect/features/authentication/models/refresh_token_response.dart';
import 'package:crisant_connect/features/authentication/models/send_otp_response.dart';
import 'package:crisant_connect/features/authentication/models/verify_otp_response.dart';
import 'package:dio/dio.dart';

class ApiResponse<T> {
  final T? data;
  final String message;
  final bool error;
  final int status;

  ApiResponse({
    this.data,
    required this.message,
    required this.error,
    required this.status,
  });
}

class Apprepo {
  final Dio dio;

  /// ✅ Dio MUST be injected (from DioClient)
  Apprepo(this.dio);

  ///----------------------send otp-----------------------------////
  Future<ApiResponse<SendOtpResponse>> requestOtp({
    required String mobileNumber,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.login,
        data: {"mobileNumber": mobileNumber},
      );

      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData["message"]?.toString() ?? "OTP sent";

      if (statusCode == 200) {
        return ApiResponse<SendOtpResponse>(
          data: SendOtpResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<SendOtpResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData["message"]?.toString() ?? "Network error occurred"
          : "Network error occurred";

      return ApiResponse<SendOtpResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    }
  }

  Future<ApiResponse<VerifyOtpResponse>> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.verifyOtp,
        data: {"mobileNumber": mobileNumber, "otp": otp},
      );

      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;

      if (statusCode == 200) {
        final verifyOtpResponse = VerifyOtpResponse.fromJson(responseData);
        await LocalStorage.saveAuthSession(verifyOtpResponse);

        return ApiResponse<VerifyOtpResponse>(
          data: verifyOtpResponse,
          message: "OTP verified successfully",
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<VerifyOtpResponse>(
        message:
            responseData["message"]?.toString() ?? "OTP verification failed",
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData["message"]?.toString() ?? "OTP verification failed"
          : "Network error occurred";

      return ApiResponse<VerifyOtpResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    }
  }

  Future<ApiResponse<RefreshTokenResponse>> refreshToken({
    required String refreshToken,
  }) async {
    final trimmedRefreshToken = refreshToken.trim();
    if (trimmedRefreshToken.isEmpty) {
      return ApiResponse<RefreshTokenResponse>(
        message: "Refresh token is missing",
        error: true,
        status: 401,
      );
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.refreshToken,
        data: {"refreshToken": trimmedRefreshToken},
        options: Options(extra: {"skipAuthRefresh": true}),
      );

      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message =
          responseData["message"]?.toString() ?? "Session refreshed";

      if (statusCode == 200) {
        final refreshTokenResponse = RefreshTokenResponse.fromJson(
          responseData,
        );
        await LocalStorage.saveRefreshSession(refreshTokenResponse);

        return ApiResponse<RefreshTokenResponse>(
          data: refreshTokenResponse,
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<RefreshTokenResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData["message"]?.toString() ?? "Session refresh failed"
          : "Network error occurred";

      return ApiResponse<RefreshTokenResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    }
  }

  Future<ApiResponse<LogoutResponse>> logout({
    required String refreshToken,
  }) async {
    final trimmedRefreshToken = refreshToken.trim();
    if (trimmedRefreshToken.isEmpty) {
      return ApiResponse<LogoutResponse>(
        message: "Refresh token is missing",
        error: true,
        status: 401,
      );
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.logout,
        data: {"refreshToken": trimmedRefreshToken},
        options: Options(extra: {"skipAuthRefresh": true}),
      );

      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData["message"]?.toString() ?? "Logged out";

      if (statusCode == 200) {
        final logoutResponse = LogoutResponse.fromJson(responseData);

        return ApiResponse<LogoutResponse>(
          data: logoutResponse,
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<LogoutResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData["message"]?.toString() ?? "Logout failed"
          : "Network error occurred";

      return ApiResponse<LogoutResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    }
  }

  void dispose() {
    dio.close();
  }
}
