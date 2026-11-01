import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/network.dart';
import 'package:ziesocial/view/register_view.dart';
import 'package:ziesocial/viewmodel/comments_viewmodel.dart';
import 'package:ziesocial/viewmodel/create_post_viewmodel.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/viewmodel/register_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        // Saat masuk aplikasi, menampilkan menu register terlebih dahulu
        home: const RegisterView(),
      ),
    );
  }
}