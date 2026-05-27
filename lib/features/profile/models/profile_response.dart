class ProfileResponse {
  final ProfileUser user;

  const ProfileResponse({required this.user});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return ProfileResponse(
      user: rawUser is Map<String, dynamic>
          ? ProfileUser.fromJson(rawUser)
          : const ProfileUser.empty(),
    );
  }
}

class ProfileUpdateRequest {
  final String fullName;
  final String mobileNumber;

  const ProfileUpdateRequest({
    required this.fullName,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'mobileNumber': mobileNumber};
  }
}

class ProfileUser {
  final int id;
  final String fullName;
  final String mobileNumber;
  final String role;
  final int? approverId;
  final bool leadsAccess;

  const ProfileUser({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    required this.approverId,
    required this.leadsAccess,
  });

  const ProfileUser.empty()
    : id = 0,
      fullName = '',
      mobileNumber = '',
      role = '',
      approverId = null,
      leadsAccess = false;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: _readInt(json['id']),
      fullName: json['fullName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      approverId: _readNullableInt(json['approverId']),
      leadsAccess: _readBool(json['leadsAccess']),
    );
  }

  ProfileUser copyWith({
    int? id,
    String? fullName,
    String? mobileNumber,
    String? role,
    int? approverId,
    bool? leadsAccess,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      approverId: approverId ?? this.approverId,
      leadsAccess: leadsAccess ?? this.leadsAccess,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
