import 'package:crisant_connect/core/network_services.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/dashboard/models/dashboard_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DashboardRepo {
  final Dio dio;

  DashboardRepo(this.dio);

  Future<ApiResponse<DashboardResponse>> getDashboard({
    required String month,
  }) async {
    try {
      debugPrint(
        '[DashboardRepo] GET ${Endpoints.baseUrl}${Endpoints.dashboard}?month=$month',
      );
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.dashboard,
        queryParameters: {'month': month},
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Dashboard loaded';

      if (statusCode == 200) {
        return ApiResponse<DashboardResponse>(
          data: DashboardResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<DashboardResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[DashboardRepo] dashboard DioException: ${e.message}');
      debugPrint(
        '[DashboardRepo] dashboard error status: ${e.response?.statusCode}',
      );
      debugPrint('[DashboardRepo] dashboard error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load dashboard'
          : 'Network error occurred';

      return ApiResponse<DashboardResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[DashboardRepo] dashboard unexpected error: $e');
      debugPrint('[DashboardRepo] dashboard stackTrace: $stackTrace');

      return ApiResponse<DashboardResponse>(
        message: 'Failed to load dashboard',
        error: true,
        status: 500,
      );
    }
  }
}
