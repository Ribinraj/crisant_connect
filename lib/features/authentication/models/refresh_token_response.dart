import 'package:crisant_connect/features/authentication/models/verify_otp_response.dart';

class RefreshTokenResponse {
  final String token;
  final String refreshToken;
  final AuthUser user;

  const RefreshTokenResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json["token"]?.toString() ?? "",
      refreshToken: json["refreshToken"]?.toString() ?? "",
      user: AuthUser.fromJson(
        json["user"] is Map<String, dynamic>
            ? json["user"] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
    );
  }
}
