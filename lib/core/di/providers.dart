import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../pocketbase/pb_client.dart';
import '../constants/app_constants.dart';

/// PocketBase 客户端 Provider（全局单例）
final pbClientProvider = Provider<PocketBase>((ref) {
  return PbClient.instance.pb;
});

/// 认证状态 Provider（响应式）
///
/// 订阅 AuthStore.onChange 流，认证状态变化时自动通知所有依赖方
///（路由器、UI 等），无需手动刷新。
final isAuthenticatedProvider = NotifierProvider<AuthWatcher, bool>(
  AuthWatcher.new,
);

class AuthWatcher extends Notifier<bool> {
  StreamSubscription? _sub;

  @override
  bool build() {
    // 清理旧订阅（build 可能被多次调用）
    _sub?.cancel();
    final pb = ref.watch(pbClientProvider);

    // 每当认证状态变化（登录/登出/Token 刷新），更新 state
    _sub = pb.authStore.onChange.listen((_) {
      state = pb.authStore.isValid;
    });

    ref.onDispose(() => _sub?.cancel());

    return pb.authStore.isValid;
  }
}

/// 当前登录用户 ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  final pb = ref.watch(pbClientProvider);
  return pb.authStore.record?.id;
});

/// PocketBase 后端 URL Provider
final pocketBaseUrlProvider = Provider<String>((ref) {
  return AppConstants.pocketBaseUrl;
});
