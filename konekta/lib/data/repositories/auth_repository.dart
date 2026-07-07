import '../../core/api_client.dart';
import '../../core/session.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient api;
  final Session session;

  AuthRepository(this.api, this.session);

  Future<AppUser> login({required String email, required String password}) async {
    final data = await api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final map = Map<String, dynamic>.from(data as Map);
    final token = map['token'] as String;
    final userMap = Map<String, dynamic>.from(map['user'] as Map);

    await session.save(
      token: token,
      role: (userMap['role'] ?? 'influencer') as String,
      userId: (userMap['id'] is num)
          ? (userMap['id'] as num).toInt()
          : int.tryParse('${userMap['id']}') ?? 0,
      name: (userMap['name'] ?? '') as String,
    );

    return AppUser.fromJson(userMap);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? username,
    String? brandName,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (username != null && username.isNotEmpty) 'username': username,
      if (brandName != null && brandName.isNotEmpty) 'brand_name': brandName,
    };
    final data = await api.post('/auth/register', body, auth: false);
    final map = Map<String, dynamic>.from(data as Map);
    final token = map['token'] as String;
    final userMap = Map<String, dynamic>.from(map['user'] as Map);

    await session.save(
      token: token,
      role: (userMap['role'] ?? role) as String,
      userId: (userMap['id'] is num)
          ? (userMap['id'] as num).toInt()
          : int.tryParse('${userMap['id']}') ?? 0,
      name: (userMap['name'] ?? name) as String,
    );

    return AppUser.fromJson(userMap);
  }

  Future<void> logout() async {
    await session.clear();
  }
}
