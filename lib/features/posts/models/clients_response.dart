class ClientsResponse {
  final List<ClientModel> clients;

  const ClientsResponse({required this.clients});

  factory ClientsResponse.fromJson(Map<String, dynamic> json) {
    final rawClients = json['clients'];
    return ClientsResponse(
      clients: rawClients is List
          ? rawClients
                .whereType<Map<String, dynamic>>()
                .map(ClientModel.fromJson)
                .toList()
          : const [],
    );
  }
}

class ClientModel {
  final int id;
  final String name;
  final String mobileNumbers;
  final String emailAddress;
  final String leadNotificationMobileNumbers;
  final String leadNotificationEmailAddresses;
  final int leadAutoResponseEnabled;
  final String leadAutoResponsePhoneNumber;
  final String completeAddress;
  final String websiteAddress;
  final int connectedProfiles;
  final int totalPosts;
  final int totalStories;
  final int totalReels;
  final int facebookSocialAccountId;
  final int instagramSocialAccountId;
  final String facebookProfileName;
  final String instagramProfileName;

  const ClientModel({
    required this.id,
    required this.name,
    required this.mobileNumbers,
    required this.emailAddress,
    required this.leadNotificationMobileNumbers,
    required this.leadNotificationEmailAddresses,
    required this.leadAutoResponseEnabled,
    required this.leadAutoResponsePhoneNumber,
    required this.completeAddress,
    required this.websiteAddress,
    required this.connectedProfiles,
    required this.totalPosts,
    required this.totalStories,
    required this.totalReels,
    required this.facebookSocialAccountId,
    required this.instagramSocialAccountId,
    required this.facebookProfileName,
    required this.instagramProfileName,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: _readInt(json['id']),
      name: json['name']?.toString() ?? '',
      mobileNumbers: json['mobile_numbers']?.toString() ?? '',
      emailAddress: json['email_address']?.toString() ?? '',
      leadNotificationMobileNumbers:
          json['lead_notification_mobile_numbers']?.toString() ?? '',
      leadNotificationEmailAddresses:
          json['lead_notification_email_addresses']?.toString() ?? '',
      leadAutoResponseEnabled: _readInt(json['lead_auto_response_enabled']),
      leadAutoResponsePhoneNumber:
          json['lead_auto_response_phone_number']?.toString() ?? '',
      completeAddress: json['complete_address']?.toString() ?? '',
      websiteAddress: json['website_address']?.toString() ?? '',
      connectedProfiles: _readInt(json['connected_profiles']),
      totalPosts: _readInt(json['total_posts']),
      totalStories: _readInt(json['total_stories']),
      totalReels: _readInt(json['total_reels']),
      facebookSocialAccountId: _readInt(json['facebook_social_account_id']),
      instagramSocialAccountId: _readInt(json['instagram_social_account_id']),
      facebookProfileName: json['facebook_profile_name']?.toString() ?? '',
      instagramProfileName: json['instagram_profile_name']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
