import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/pocketbase/pb_client.dart';
import 'core/routes/app_router.dart';
import 'core/themes/theme_notifier.dart';
import 'core/themes/shad_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive（持久化主题偏好等）
  await Hive.initFlutter();
  await initSettingsBox();

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
    final themeMode = ref.watch(themeModeProvider);
    final colorSchemeName = ref.watch(colorSchemeProvider);

    return ShadApp.custom(
      themeMode: themeMode,
      theme: createShadTheme(colorSchemeName, Brightness.light),
      darkTheme: createShadTheme(colorSchemeName, Brightness.dark),
      appBuilder: (context) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          routerConfig: router,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
          ],
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
        );
      },
    );
  }
}
