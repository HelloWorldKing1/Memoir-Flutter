import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase 客户端单例配置
///
/// 使用 AsyncAuthStore 将认证 token 持久化到 flutter_secure_storage，
/// 确保应用重启后用户仍保持登录状态。
class PbClient {
  PbClient._();

  static PbClient? _instance;
  late final PocketBase pb;

  /// 获取单例实例。首次调用前须先执行 [init]。
  static PbClient get instance {
    if (_instance == null) {
      throw StateError('PbClient not initialized. Call PbClient.init() first.');
    }
    return _instance!;
  }

  /// 初始化 PocketBase 客户端。
  ///
  /// 应在 [WidgetsFlutterBinding.ensureInitialized] 之后调用。
  /// [baseUrl] 为 PocketBase 服务地址。
  static Future<PbClient> init({required String baseUrl}) async {
    final client = PbClient._();
    const secureStorage = FlutterSecureStorage();

    // 读取上次持久化的认证数据
    final initialData = await secureStorage.read(key: 'pb_auth');

    final authStore = AsyncAuthStore(
      save: (String data) async {
        await secureStorage.write(key: 'pb_auth', value: data);
      },
      initial: initialData,
      clear: () async {
        await secureStorage.delete(key: 'pb_auth');
      },
    );

    client.pb = PocketBase(
      baseUrl,
      authStore: authStore,
    );

    _instance = client;
    return client;
  }

  /// 当前是否已认证
  bool get isAuthenticated => pb.authStore.isValid;

  /// 当前登录用户 ID（未认证返回 null）
  String? get userId => pb.authStore.record?.id;

  /// 当前登录用户模型
  RecordModel? get currentUser => pb.authStore.record;
}
