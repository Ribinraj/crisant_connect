class VerifyOtpResponse {
  final String token;
  final String refreshToken;
  final AuthUser user;

  const VerifyOtpResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
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

class AuthUser {
  final int id;
  final String fullName;
  final String mobileNumber;
  final String role;
  final int? approverId;
  final bool leadsAccess;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    required this.approverId,
    required this.leadsAccess,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json["id"] is int
          ? json["id"] as int
          : int.tryParse("${json["id"]}") ?? 0,
      fullName: json["fullName"]?.toString() ?? "",
      mobileNumber: json["mobileNumber"]?.toString() ?? "",
      role: json["role"]?.toString() ?? "",
      approverId: json["approverId"] is int
          ? json["approverId"] as int
          : int.tryParse(json["approverId"]?.toString() ?? ""),
      leadsAccess: json["leadsAccess"] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fullName": fullName,
      "mobileNumber": mobileNumber,
      "role": role,
      "approverId": approverId,
      "leadsAccess": leadsAccess,
    };
  }
}
