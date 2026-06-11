import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../pocketbase/pb_client.dart';
import '../constants/app_constants.dart';

/// PocketBase 客户端 Provider（全局单例）
///
/// 通过 [PbClient.instance] 获取已初始化的客户端。
final pbClientProvider = Provider<PocketBase>((ref) {
  return PbClient.instance.pb;
});

/// 认证状态 Provider
///
/// 封装 [PbClient] 的认证状态查询。
final authProvider = Provider<AuthStore>((ref) {
  return PbClient.instance.pb.authStore;
});

/// 当前登录用户 ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  return PbClient.instance.userId;
});

/// 是否已登录 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return PbClient.instance.isAuthenticated;
});

/// PocketBase 后端 URL Provider
final pocketBaseUrlProvider = Provider<String>((ref) {
  return AppConstants.pocketBaseUrl;
});
