import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes/app_router.dart';
import 'auth_notifier.dart';

/// 登录页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final values = _formKey.currentState!.value;
    await ref.read(authNotifierProvider.notifier).login(
          (values['email'] as String).trim(),
          values['password'] as String,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final error = authState.error;
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ShadForm(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Memoir ✨',
                    textAlign: TextAlign.center,
                    style: textTheme.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '欢迎回来',
                    textAlign: TextAlign.center,
                    style: textTheme.muted,
                  ),
                  const SizedBox(height: 40),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.destructive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 16,
                            color: scheme.destructive,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error.message,
                              style: TextStyle(
                                color: scheme.destructiveForeground,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ShadInputFormField(
                    id: 'email',
                    leading: const Icon(LucideIcons.mail, size: 18),
                    trailing: const SizedBox(width: 36, height: 36),
                    label: const Text('邮箱'),
                    placeholder: const Text('请输入邮箱'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v.isEmpty) return '请输入邮箱';
                      if (!v.contains('@')) return '邮箱格式不正确';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ShadInputFormField(
                    id: 'password',
                    leading: const Icon(LucideIcons.lock, size: 18),
                    label: const Text('密码'),
                    placeholder: const Text('请输入密码'),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    trailing: ShadIconButton.ghost(
                      iconSize: 18,
                      icon: Icon(
                        _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v.isEmpty) return '请输入密码';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ShadButton(
                    onPressed: authState.isLoading ? null : _login,
                    width: double.infinity,
                    leading: authState.isLoading
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primaryForeground,
                            ),
                          )
                        : null,
                    child: Text(
                      '登录',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ShadButton.link(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('还没有账户？去注册'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
