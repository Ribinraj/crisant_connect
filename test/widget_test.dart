import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/dashboard/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'package:crisant_connect/features/dashboard/dashboard_repo.dart';
import 'package:crisant_connect/features/dashboard/models/dashboard_response.dart';
import 'package:crisant_connect/features/dashboard/pages/screen_dashboard.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crisant_connect/main.dart';

void main() {
  testWidgets('shows login screen after splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Welcome to Crisant Connect'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('dashboard renders without vertical overflow on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DashboardBloc(dashboardRepo: _FakeDashboardRepo()),
          child: const ScreenDashboard(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

class _FakeDashboardRepo extends DashboardRepo {
  _FakeDashboardRepo() : super(Dio());

  @override
  Future<ApiResponse<DashboardResponse>> getDashboard({
    required String month,
  }) async {
    final now = DateTime.now();
    final monthParts = month.split('-');
    final year = monthParts.isNotEmpty
        ? int.tryParse(monthParts.first) ?? now.year
        : now.year;
    final monthNumber = monthParts.length > 1
        ? int.tryParse(monthParts[1]) ?? now.month
        : now.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, monthNumber);

    return ApiResponse<DashboardResponse>(
      data: DashboardResponse(
        stats: const DashboardStats(
          clients: 8,
          connectedProfiles: 12,
          queuedPosts: 5,
          pendingApprovals: 2,
        ),
        month: DashboardMonth(
          key: month,
          timezone: 'Asia/Kolkata',
          days: daysInMonth,
        ),
        monthlyPostingOverview: List.generate(
          daysInMonth,
          (index) => MonthlyPostingOverviewItem(
            date: DateTime(year, monthNumber, index + 1),
            day: index + 1,
            instagram: index.isEven ? 1 : 0,
            facebook: index.isOdd ? 1 : 0,
          ),
        ),
        postingGapMonitor: const [],
        recentPosts: const [],
        generatedAt: now,
      ),
      message: 'Dashboard loaded',
      error: false,
      status: 200,
    );
  }
}
