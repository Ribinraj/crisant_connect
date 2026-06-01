import 'package:crisant_connect/core/network_services.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approuter.dart';
import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/authentication/blocs/logout_bloc/logout_bloc.dart';
import 'package:crisant_connect/features/authentication/blocs/refresh_token_bloc/refresh_token_bloc.dart';
import 'package:crisant_connect/features/authentication/blocs/send_otp_bloc/send_otp_bloc.dart';
import 'package:crisant_connect/features/authentication/blocs/verify_otp_bloc/verify_otp_bloc.dart';
import 'package:crisant_connect/features/dashboard/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'package:crisant_connect/features/dashboard/dashboard_repo.dart';
import 'package:crisant_connect/features/gallery/blocs/media_library_bloc/media_library_bloc.dart';
import 'package:crisant_connect/features/notifications/blocs/notifications_bloc/notifications_bloc.dart';
import 'package:crisant_connect/features/notifications/notifications_repo.dart';
import 'package:crisant_connect/features/posts/blocs/clients_bloc/clients_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/create_post_bloc/create_post_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/post_mutation_bloc/post_mutation_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/posts_list_bloc/posts_list_bloc.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:crisant_connect/features/profile/blocs/profile_bloc/profile_bloc.dart';
import 'package:crisant_connect/features/profile/profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);
    final dio = DioClient.create(context);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => Apprepo(dio),
          dispose: (apprepo) => apprepo.dispose(),
        ),
        RepositoryProvider(create: (_) => PostRepo(dio)),
        RepositoryProvider(create: (_) => DashboardRepo(dio)),
        RepositoryProvider(create: (_) => ProfileRepo(dio)),
        RepositoryProvider(create: (_) => NotificationsRepo(dio)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SendOtpBloc(apprepo: context.read<Apprepo>()),
          ),
          BlocProvider(
            create: (context) =>
                VerifyOtpBloc(apprepo: context.read<Apprepo>()),
          ),
          BlocProvider(
            create: (context) =>
                RefreshTokenBloc(apprepo: context.read<Apprepo>()),
          ),
          BlocProvider(
            create: (context) => LogoutBloc(apprepo: context.read<Apprepo>()),
          ),
          BlocProvider(
            create: (context) =>
                ClientsBloc(postRepo: context.read<PostRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                DashboardBloc(dashboardRepo: context.read<DashboardRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                MediaLibraryBloc(postRepo: context.read<PostRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                CreatePostBloc(postRepo: context.read<PostRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                PostMutationBloc(postRepo: context.read<PostRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                PostsListBloc(postRepo: context.read<PostRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                ProfileBloc(profileRepo: context.read<ProfileRepo>()),
          ),
          BlocProvider(
            create: (context) => NotificationsBloc(
              notificationsRepo: context.read<NotificationsRepo>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
