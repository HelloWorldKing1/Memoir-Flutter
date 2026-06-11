import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';

/// 认证错误信息
class AuthError {
  final String message;
  const AuthError(this.message);
}

/// 认证状态
class AuthState {
  final bool isLoading;
  final AuthError? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, AuthError? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 认证逻辑控制器
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// 登录
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pb = ref.read(pbClientProvider);
      await pb.collection('users').authWithPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on ClientException catch (e) {
      final msg = _handleError(e);
      state = state.copyWith(isLoading: false, error: AuthError(msg));
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (password != passwordConfirm) {
      state = state.copyWith(
        isLoading: false,
        error: const AuthError('两次密码不一致'),
      );
      return false;
    }

    try {
      final pb = ref.read(pbClientProvider);
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
      };
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }

      await pb.collection('users').create(body: body);
      // 注册成功后自动登录
      await pb.collection('users').authWithPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on ClientException catch (e) {
      final msg = _handleError(e);
      state = state.copyWith(isLoading: false, error: AuthError(msg));
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 解析 PocketBase 错误信息
  String _handleError(ClientException e) {
    final data = e.response;
    if (data['message'] != null) {
      return data['message'].toString();
    }
    if (data['email'] != null) {
      return data['email']['message'] ?? '邮箱格式不正确';
    }
    if (data['password'] != null) {
      return data['password']['message'] ?? '密码不符合要求';
    }
    return '操作失败，请重试';
  }
}

/// AuthNotifier Provider
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
