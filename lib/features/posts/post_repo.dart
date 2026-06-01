import 'package:crisant_connect/core/network_services.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/gallery/models/uploads_response.dart';
import 'package:crisant_connect/features/posts/models/clients_response.dart';
import 'package:crisant_connect/features/posts/models/create_post_models.dart';
import 'package:crisant_connect/features/posts/models/post_mutation_models.dart';
import 'package:crisant_connect/features/posts/models/posts_list_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PostRepo {
  final Dio dio;

  PostRepo(this.dio);

  Future<ApiResponse<ClientsResponse>> getClients() async {
    try {
      debugPrint('[PostRepo] GET ${Endpoints.baseUrl}${Endpoints.clients}');
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.clients,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Clients loaded';

      debugPrint('[PostRepo] clients status: $statusCode');
      debugPrint('[PostRepo] clients response: $responseData');

      if (statusCode == 200) {
        return ApiResponse<ClientsResponse>(
          data: ClientsResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<ClientsResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] clients DioException: ${e.message}');
      debugPrint('[PostRepo] clients error status: ${e.response?.statusCode}');
      debugPrint('[PostRepo] clients error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load clients'
          : 'Network error occurred';

      return ApiResponse<ClientsResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] clients unexpected error: $e');
      debugPrint('[PostRepo] clients stackTrace: $stackTrace');

      return ApiResponse<ClientsResponse>(
        message: 'Failed to load clients',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<UploadsResponse>> getUploads({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint(
        '[PostRepo] GET ${Endpoints.baseUrl}${Endpoints.uploads}?page=$page&limit=$limit',
      );
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.uploads,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Uploads loaded';

      debugPrint('[PostRepo] uploads status: $statusCode');
      debugPrint('[PostRepo] uploads response: $responseData');

      if (statusCode == 200) {
        return ApiResponse<UploadsResponse>(
          data: UploadsResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<UploadsResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] uploads DioException: ${e.message}');
      debugPrint('[PostRepo] uploads error status: ${e.response?.statusCode}');
      debugPrint('[PostRepo] uploads error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load uploads'
          : 'Network error occurred';

      return ApiResponse<UploadsResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] uploads unexpected error: $e');
      debugPrint('[PostRepo] uploads stackTrace: $stackTrace');

      return ApiResponse<UploadsResponse>(
        message: 'Failed to load uploads',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<CreatePostResponse>> createPost(
    CreatePostRequest request,
  ) async {
    try {
      debugPrint('[PostRepo] POST ${Endpoints.baseUrl}${Endpoints.posts}');
      final response = await dio.post<Map<String, dynamic>>(
        Endpoints.posts,
        data: request.toJson(),
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Post created';

      debugPrint('[PostRepo] create post status: $statusCode');
      debugPrint('[PostRepo] create post response: $responseData');

      if (statusCode == 201) {
        return ApiResponse<CreatePostResponse>(
          data: CreatePostResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<CreatePostResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] create post DioException: ${e.message}');
      debugPrint(
        '[PostRepo] create post error status: ${e.response?.statusCode}',
      );
      debugPrint('[PostRepo] create post error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to create post'
          : 'Network error occurred';

      return ApiResponse<CreatePostResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] create post unexpected error: $e');
      debugPrint('[PostRepo] create post stackTrace: $stackTrace');

      return ApiResponse<CreatePostResponse>(
        message: 'Failed to create post',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<PostMutationResponse>> editPost({
    required int postId,
    required CreatePostRequest request,
  }) async {
    try {
      final path = '${Endpoints.posts}/$postId';
      debugPrint('[PostRepo] PATCH ${Endpoints.baseUrl}$path');
      final response = await dio.patch<Map<String, dynamic>>(
        path,
        data: request.toJson(),
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Post updated';

      debugPrint('[PostRepo] edit post status: $statusCode');
      debugPrint('[PostRepo] edit post response: $responseData');

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse<PostMutationResponse>(
          data: PostMutationResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<PostMutationResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] edit post DioException: ${e.message}');
      debugPrint(
        '[PostRepo] edit post error status: ${e.response?.statusCode}',
      );
      debugPrint('[PostRepo] edit post error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to update post'
          : 'Network error occurred';

      return ApiResponse<PostMutationResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] edit post unexpected error: $e');
      debugPrint('[PostRepo] edit post stackTrace: $stackTrace');

      return ApiResponse<PostMutationResponse>(
        message: 'Failed to update post',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<PostMutationResponse>> deletePost({
    required int postId,
  }) async {
    try {
      final path = '${Endpoints.posts}/$postId';
      debugPrint('[PostRepo] DELETE ${Endpoints.baseUrl}$path');
      final response = await dio.delete<Map<String, dynamic>>(
        path,
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Post deleted';

      debugPrint('[PostRepo] delete post status: $statusCode');
      debugPrint('[PostRepo] delete post response: $responseData');

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse<PostMutationResponse>(
          data: PostMutationResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<PostMutationResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] delete post DioException: ${e.message}');
      debugPrint(
        '[PostRepo] delete post error status: ${e.response?.statusCode}',
      );
      debugPrint('[PostRepo] delete post error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to delete post'
          : 'Network error occurred';

      return ApiResponse<PostMutationResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] delete post unexpected error: $e');
      debugPrint('[PostRepo] delete post stackTrace: $stackTrace');

      return ApiResponse<PostMutationResponse>(
        message: 'Failed to delete post',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<PostsListResponse>> getPosts({
    required String view,
  }) async {
    try {
      debugPrint(
        '[PostRepo] GET ${Endpoints.baseUrl}${Endpoints.posts}?view=$view',
      );
      final response = await dio.get<Map<String, dynamic>>(
        Endpoints.posts,
        queryParameters: {'view': view},
        options: Options(extra: {DioClient.skipUnauthorizedRedirectKey: true}),
      );
      final responseData = response.data ?? {};
      final statusCode = response.statusCode ?? 500;
      final message = responseData['message']?.toString() ?? 'Posts loaded';

      debugPrint('[PostRepo] posts status: $statusCode');
      final rawPosts = responseData['posts'];
      debugPrint(
        '[PostRepo] posts count: ${rawPosts is List ? rawPosts.length : 0}',
      );

      if (statusCode == 200) {
        return ApiResponse<PostsListResponse>(
          data: PostsListResponse.fromJson(responseData),
          message: message,
          error: false,
          status: statusCode,
        );
      }

      return ApiResponse<PostsListResponse>(
        message: message,
        error: true,
        status: statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      debugPrint('[PostRepo] posts DioException: ${e.message}');
      debugPrint('[PostRepo] posts error status: ${e.response?.statusCode}');
      debugPrint('[PostRepo] posts error response: $responseData');
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString() ?? 'Failed to load posts'
          : 'Network error occurred';

      return ApiResponse<PostsListResponse>(
        message: message,
        error: true,
        status: e.response?.statusCode ?? 500,
      );
    } catch (e, stackTrace) {
      debugPrint('[PostRepo] posts unexpected error: $e');
      debugPrint('[PostRepo] posts stackTrace: $stackTrace');

      return ApiResponse<PostsListResponse>(
        message: 'Failed to load posts',
        error: true,
        status: 500,
      );
    }
  }
}
