import 'package:crisant_connect/core/network_services.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/notifications/models/notifications_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationsRepo {
  final Dio dio;

  NotificationsRepo(this.dio);

  Future<ApiResponse<NotificationsResponse>> getNotifications() async {
    try {
      debugPrint(
        '[NotificationsRepo] GET ${Endpoints.baseUrl}${Endpoints.notifications}',
      );
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.notifications,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message =
          responseData['message']?.toString() ?? 'Notifications loaded';

      if (statusCode == 200) {
        return ApiResponse<NotificationsResponse>(
          data: NotificationsResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<NotificationsResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint(
        '[NotificationsRepo] notifications DioException: ${e.message}',
      );
      debugPrint(
        '[NotificationsRepo] notifications error status: ${e.response?.statusCode}',
      );
      debugPrint(
        '[NotificationsRepo] notifications error response: $responseData',
      );
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ??
                'Failed to load notifications'
          : 'Network error occurred';

      return ApiResponse<NotificationsResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[NotificationsRepo] notifications unexpected error: $e');
      debugPrint('[NotificationsRepo] notifications stackTrace: $stackTrace');

      return ApiResponse<NotificationsResponse>(
        message: 'Failed to load notifications',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<UnreadCountResponse>> getUnreadCount() async {
    try {
      debugPrint(
        '[NotificationsRepo] GET ${Endpoints.baseUrl}${Endpoints.notificationsUnreadCount}',
      );
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.notificationsUnreadCount,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message =
          responseData['message']?.toString() ?? 'Unread count loaded';

      if (statusCode == 200) {
        return ApiResponse<UnreadCountResponse>(
          data: UnreadCountResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<UnreadCountResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[NotificationsRepo] unread count DioException: ${e.message}');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load unread count'
          : 'Network error occurred';

      return ApiResponse<UnreadCountResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[NotificationsRepo] unread count unexpected error: $e');
      debugPrint('[NotificationsRepo] unread count stackTrace: $stackTrace');

      return ApiResponse<UnreadCountResponse>(
        message: 'Failed to load unread count',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<MarkNotificationReadResponse>> markAsRead(int id) async {
    try {
      final path = Endpoints.notificationRead(id);
      debugPrint('[NotificationsRepo] POST ${Endpoints.baseUrl}$path');
      final response = await dio.post<Map<String, dynamic>>(
        path,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message =
          responseData['message']?.toString() ?? 'Notification marked as read';

      if (statusCode == 200) {
        return ApiResponse<MarkNotificationReadResponse>(
          data: MarkNotificationReadResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<MarkNotificationReadResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[NotificationsRepo] mark read DioException: ${e.message}');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ??
                'Failed to mark notification as read'
          : 'Network error occurred';

      return ApiResponse<MarkNotificationReadResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[NotificationsRepo] mark read unexpected error: $e');
      debugPrint('[NotificationsRepo] mark read stackTrace: $stackTrace');

      return ApiResponse<MarkNotificationReadResponse>(
        message: 'Failed to mark notification as read',
        error: true,
        status: 500,
      );
    }
  }
}
