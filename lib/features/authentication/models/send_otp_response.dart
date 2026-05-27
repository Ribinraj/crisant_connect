class SendOtpResponse {
  final bool ok;
  final String mobileNumber;
  final String maskedMobileNumber;
  final int resendAfterSeconds;
  final int expiresInSeconds;

  const SendOtpResponse({
    required this.ok,
    required this.mobileNumber,
    required this.maskedMobileNumber,
    required this.resendAfterSeconds,
    required this.expiresInSeconds,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      ok: json["ok"] == true,
      mobileNumber: json["mobileNumber"]?.toString() ?? "",
      maskedMobileNumber: json["maskedMobileNumber"]?.toString() ?? "",
      resendAfterSeconds: json["resendAfterSeconds"] is int
          ? json["resendAfterSeconds"] as int
          : int.tryParse(json["resendAfterSeconds"]?.toString() ?? "") ?? 30,
      expiresInSeconds: json["expiresInSeconds"] is int
          ? json["expiresInSeconds"] as int
          : int.tryParse(json["expiresInSeconds"]?.toString() ?? "") ?? 0,
    );
  }
}
