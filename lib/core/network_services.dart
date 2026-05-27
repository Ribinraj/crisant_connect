import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/core/routes/approuter.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/models/refresh_token_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DioClient {
  static const _skipAuthRefreshKey = 'skipAuthRefresh';
  static const skipUnauthorizedRedirectKey = 'skipUnauthorizedRedirect';

  static Dio create(BuildContext context) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        /// ✅ ADD TOKEN AUTOMATICALLY
        onRequest: (options, handler) async {
          final shouldSkipAuth =
              options.extra[_skipAuthRefreshKey] == true ||
              options.path == Endpoints.refreshToken;

          if (!shouldSkipAuth) {
            final token = await LocalStorage.getToken();
            debugPrint('[DioClient] ${options.method} ${options.path}');
            debugPrint('[DioClient] token available: ${token.isNotEmpty}');
            if (token.isNotEmpty) {
              final authHeader = _authHeader(token);
              debugPrint(
                '[DioClient] auth header uses bearer: '
                '${authHeader.startsWith('Bearer ')}',
              );
              debugPrint('[DioClient] token length: ${token.length}');
              options.headers['Authorization'] = authHeader;
            }
          }
          handler.next(options);
        },

        /// HANDLE 401 GLOBALLY
        onError: (DioException e, handler) async {
          debugPrint(
            '[DioClient] error ${e.requestOptions.method} '
            '${e.requestOptions.path}: ${e.response?.statusCode}',
          );
          debugPrint('[DioClient] error response: ${e.response?.data}');

          final isUnauthorized = e.response?.statusCode == 401;
          final shouldSkipRefresh =
              e.requestOptions.extra[_skipAuthRefreshKey] == true ||
              e.requestOptions.path == Endpoints.refreshToken;
          final shouldSkipUnauthorizedRedirect =
              e.requestOptions.extra[skipUnauthorizedRedirectKey] == true;

          if (isUnauthorized && !shouldSkipRefresh) {
            final refreshedSession = await _refreshSession(dio);

            if (refreshedSession != null) {
              try {
                final retryResponse = await _retryRequest(
                  dio,
                  e.requestOptions,
                  refreshedSession.token,
                );
                handler.resolve(retryResponse);
                return;
              } on DioException catch (retryError) {
                if (shouldSkipUnauthorizedRedirect) {
                  handler.next(retryError);
                  return;
                }
                if (!context.mounted) {
                  handler.next(retryError);
                  return;
                }
                await _handleUnauthorized(context, retryError);
                handler.next(retryError);
                return;
              }
            }

            if (shouldSkipUnauthorizedRedirect) {
              handler.next(e);
              return;
            }

            if (!context.mounted) {
              handler.next(e);
              return;
            }
            await _handleUnauthorized(context, e);
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  static Future<RefreshTokenResponse?> _refreshSession(Dio dio) async {
    final refreshToken = await LocalStorage.getRefreshToken();
    if (refreshToken.isEmpty) {
      debugPrint('[DioClient] refresh token missing');
      return null;
    }

    try {
      debugPrint('[DioClient] refreshing session');
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.refreshToken,
        data: {"refreshToken": refreshToken},
        options: Options(extra: {_skipAuthRefreshKey: true}),
      );

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('[DioClient] refresh failed: ${response.statusCode}');
        debugPrint('[DioClient] refresh response: ${response.data}');
        return null;
      }

      debugPrint('[DioClient] refresh success');
      final refreshedSession = RefreshTokenResponse.fromJson(response.data!);
      await LocalStorage.saveRefreshSession(refreshedSession);
      return refreshedSession;
    } on DioException catch (e) {
      debugPrint('[DioClient] refresh DioException: ${e.message}');
      debugPrint('[DioClient] refresh error response: ${e.response?.data}');
      return null;
    }
  }

  static Future<Response<dynamic>> _retryRequest(
    Dio dio,
    RequestOptions requestOptions,
    String token,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = _authHeader(token);

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        followRedirects: requestOptions.followRedirects,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        extra: {...requestOptions.extra, _skipAuthRefreshKey: true},
      ),
    );
  }

  static String _authHeader(String token) {
    final trimmedToken = token.trim();
    if (trimmedToken.toLowerCase().startsWith('bearer ')) {
      return trimmedToken;
    }
    return 'Bearer $trimmedToken';
  }

  static Future<void> _handleUnauthorized(
    BuildContext context,
    DioException e,
  ) async {
    if (!context.mounted) return;

    final responseData = e.response?.data;
    final message = responseData is Map<String, dynamic>
        ? responseData['message']?.toString()
        : null;

    debugPrint('[DioClient] unauthorized: ${message ?? 'Session expired'}');

    if (Localizations.maybeLocaleOf(context) == null) {
      return;
    }

    // Clear local session only when we have a Material context for user-facing handling.
    await LocalStorage.clearAll();
    if (!context.mounted) return;

    // Show popup
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: Text(
          message ?? 'Your session has expired. Please login again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              AppRouter.router.go(Approtes.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
