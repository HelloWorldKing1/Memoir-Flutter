import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/diary/diary_list_page.dart';
import '../../features/diary/diary_detail_page.dart';
import '../../features/diary/diary_editor_page.dart';
import '../../features/statistics/statistics_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shared/app_shell.dart';
import '../../data/models/enums.dart';
import '../di/providers.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const diaryList = '/diary';
  static const statistics = '/statistics';
  static const settings = '/settings';
  static const diaryDetail = '/diary/:id';
  static const diaryNew = '/diary/new';
  static const diaryEdit = '/diary/:id/edit';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 应用路由配置
///
/// 使用 go_router 声明式路由 + Riverpod 认证守卫。
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final loggedIn = isAuth;
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      final goingToRegister = state.matchedLocation == AppRoutes.register;

      // 未登录 → 跳转登录页
      if (!loggedIn && !goingToLogin && !goingToRegister) {
        return AppRoutes.login;
      }

      // 已登录访问登录/注册 → 跳转首页
      if (loggedIn && (goingToLogin || goingToRegister)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // 首页（Dashboard）
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          // 日记列表
          GoRoute(
            path: AppRoutes.diaryList,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiaryListPage(),
            ),
          ),
          // 统计
          GoRoute(
            path: AppRoutes.statistics,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatisticsPage(),
            ),
          ),
          // 设置
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
          // 新建日记（extra 可为 EntryType 预选类型）
          GoRoute(
            path: AppRoutes.diaryNew,
            builder: (context, state) {
              final entryType = state.extra is EntryType ? state.extra as EntryType : null;
              return DiaryEditorPage(initialEntryType: entryType);
            },
          ),
          // 编辑日记
          GoRoute(
            path: AppRoutes.diaryEdit,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DiaryEditorPage(diaryId: id);
            },
          ),
          // 日记详情
          GoRoute(
            path: AppRoutes.diaryDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DiaryDetailPage(diaryId: id);
            },
          ),
        ],
      ),
    ],
  );
});
