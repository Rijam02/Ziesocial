
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/view/splash_view.dart';
import 'package:ziesocial/viewmodel/comments_viewmodel.dart';
import 'package:ziesocial/viewmodel/create_post_viewmodel.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/viewmodel/register_viewmodel.dart';

final PusherChannelsFlutter pusher =
    PusherChannelsFlutter.getInstance();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await pusher.init(
    apiKey: '56c15636a619292a7a0f',
    cluster: 'ap1',
  );

  await pusher.connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => CreatePostViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentsViewModel(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'ZieSocial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashView(),
      ),
    );
  }
}
