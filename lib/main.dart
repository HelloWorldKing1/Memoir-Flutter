import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/pocketbase/pb_client.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 PocketBase 客户端（连接本地服务）
  await PbClient.init(baseUrl: AppConstants.pocketBaseUrl);

  runApp(
    const ProviderScope(
      child: MemoirApp(),
    ),
  );
}

class MemoirApp extends ConsumerWidget {
  const MemoirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
