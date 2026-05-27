import 'package:crisant_connect/core/network_services.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/profile/models/profile_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProfileRepo {
  final Dio dio;

  ProfileRepo(this.dio);

  Future<ApiResponse<ProfileResponse>> getProfile() async {
    try {
      debugPrint('[ProfileRepo] GET ${Endpoints.baseUrl}${Endpoints.me}');
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.me,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Profile loaded';

      if (statusCode == 200) {
        return ApiResponse<ProfileResponse>(
          data: ProfileResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<ProfileResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[ProfileRepo] profile DioException: ${e.message}');
      debugPrint(
        '[ProfileRepo] profile error status: ${e.response?.statusCode}',
      );
      debugPrint('[ProfileRepo] profile error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load profile'
          : 'Network error occurred';

      return ApiResponse<ProfileResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[ProfileRepo] profile unexpected error: $e');
      debugPrint('[ProfileRepo] profile stackTrace: $stackTrace');

      return ApiResponse<ProfileResponse>(
        message: 'Failed to load profile',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<ProfileResponse>> updateProfile(
    ProfileUpdateRequest request,
  ) async {
    try {
      debugPrint('[ProfileRepo] PATCH ${Endpoints.baseUrl}${Endpoints.me}');
      final response = await dio.patch<Map<String, dynamic>>(
        Endpoints.me,
        data: request.toJson(),
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Profile updated';

      if (statusCode >= 200 && statusCode < 300) {
        final profileResponse = ProfileResponse.fromJson(responseData);

        return ApiResponse<ProfileResponse>(
          data: profileResponse,
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<ProfileResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[ProfileRepo] update profile DioException: ${e.message}');
      debugPrint(
        '[ProfileRepo] update profile error status: ${e.response?.statusCode}',
      );
      debugPrint('[ProfileRepo] update profile error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to update profile'
          : 'Network error occurred';

      return ApiResponse<ProfileResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[ProfileRepo] update profile unexpected error: $e');
      debugPrint('[ProfileRepo] update profile stackTrace: $stackTrace');

      return ApiResponse<ProfileResponse>(
        message: 'Failed to update profile',
        error: true,
        status: 500,
      );
    }
  }
}
