class LogoutResponse {
  final bool ok;

  const LogoutResponse({required this.ok});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(ok: json["ok"] == true);
  }
}
