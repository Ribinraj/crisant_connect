class DashboardResponse {
  final DashboardStats stats;
  final DashboardMonth month;
  final List<MonthlyPostingOverviewItem> monthlyPostingOverview;
  final List<PostingGapItem> postingGapMonitor;
  final List<DashboardRecentPost> recentPosts;
  final DateTime? generatedAt;

  const DashboardResponse({
    required this.stats,
    required this.month,
    required this.monthlyPostingOverview,
    required this.postingGapMonitor,
    required this.recentPosts,
    required this.generatedAt,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final rawCharts = json['charts'];
    final charts = rawCharts is Map<String, dynamic>
        ? rawCharts
        : const <String, dynamic>{};

    return DashboardResponse(
      stats: DashboardStats.fromJson(_readMap(json['stats'])),
      month: DashboardMonth.fromJson(_readMap(json['month'])),
      monthlyPostingOverview: _readList(
        charts['monthlyPostingOverview'],
      ).map(MonthlyPostingOverviewItem.fromJson).toList(),
      postingGapMonitor: _readList(
        json['postingGapMonitor'],
      ).map(PostingGapItem.fromJson).toList(),
      recentPosts: _readList(
        json['recentPosts'],
      ).map(DashboardRecentPost.fromJson).toList(),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    return value is Map<String, dynamic> ? value : const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }
}

class DashboardStats {
  final int clients;
  final int connectedProfiles;
  final int queuedPosts;
  final int pendingApprovals;

  const DashboardStats({
    required this.clients,
    required this.connectedProfiles,
    required this.queuedPosts,
    required this.pendingApprovals,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      clients: _readInt(json['clients']),
      connectedProfiles: _readInt(json['connectedProfiles']),
      queuedPosts: _readInt(json['queuedPosts']),
      pendingApprovals: _readInt(json['pendingApprovals']),
    );
  }
}

class DashboardMonth {
  final String key;
  final String timezone;
  final int days;

  const DashboardMonth({
    required this.key,
    required this.timezone,
    required this.days,
  });

  factory DashboardMonth.fromJson(Map<String, dynamic> json) {
    return DashboardMonth(
      key: json['key']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? '',
      days: _readInt(json['days']),
    );
  }
}

class MonthlyPostingOverviewItem {
  final DateTime? date;
  final int day;
  final int instagram;
  final int facebook;

  const MonthlyPostingOverviewItem({
    required this.date,
    required this.day,
    required this.instagram,
    required this.facebook,
  });

  factory MonthlyPostingOverviewItem.fromJson(Map<String, dynamic> json) {
    return MonthlyPostingOverviewItem(
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      day: _readInt(json['day']),
      instagram: _readInt(json['instagram']),
      facebook: _readInt(json['facebook']),
    );
  }

  int get total => instagram + facebook;

  String get label {
    final value = day > 0 ? day : date?.day ?? 0;
    return value > 0 ? value.toString() : '-';
  }
}

class PostingGapItem {
  final int clientId;
  final String clientName;
  final String lastPostTitle;
  final DateTime? lastPostedAt;
  final int gapDays;
  final GapSeverity severity;

  const PostingGapItem({
    required this.clientId,
    required this.clientName,
    required this.lastPostTitle,
    required this.lastPostedAt,
    required this.gapDays,
    required this.severity,
  });

  factory PostingGapItem.fromJson(Map<String, dynamic> json) {
    return PostingGapItem(
      clientId: _readInt(json['clientId']),
      clientName: json['clientName']?.toString() ?? '',
      lastPostTitle: json['lastPostTitle']?.toString() ?? '',
      lastPostedAt: DateTime.tryParse(json['lastPostedAt']?.toString() ?? ''),
      gapDays: _readInt(json['gapDays']),
      severity: GapSeverity.fromJson(
        json['severity'] is Map<String, dynamic>
            ? json['severity'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
    );
  }
}

class GapSeverity {
  final String tone;
  final String label;
  final String detail;

  const GapSeverity({
    required this.tone,
    required this.label,
    required this.detail,
  });

  factory GapSeverity.fromJson(Map<String, dynamic> json) {
    return GapSeverity(
      tone: json['tone']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class DashboardRecentPost {
  final int id;
  final int postId;
  final String title;
  final String platform;
  final String profileName;
  final DateTime? scheduledFor;
  final String status;
  final String clientName;

  const DashboardRecentPost({
    required this.id,
    required this.postId,
    required this.title,
    required this.platform,
    required this.profileName,
    required this.scheduledFor,
    required this.status,
    required this.clientName,
  });

  factory DashboardRecentPost.fromJson(Map<String, dynamic> json) {
    return DashboardRecentPost(
      id: _readInt(json['id']),
      postId: _readInt(json['post_id'] ?? json['postId']),
      title: json['title']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      profileName: json['profile_name']?.toString() ?? '',
      scheduledFor: DateTime.tryParse(json['scheduled_for']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
