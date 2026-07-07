import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'core/session.dart';
import 'core/app_scope.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'Opening/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final session = Session(prefs);
  final api = ApiClient(session);
  final authRepo = AuthRepository(api, session);
  final profileRepo = ProfileRepository(api);
  final chatRepo = ChatRepository(api);
  final notificationRepo = NotificationRepository(api);
  final subscriptionRepo = SubscriptionRepository(api);
  runApp(KonektaApp(
    session: session,
    api: api,
    authRepo: authRepo,
    profileRepo: profileRepo,
    chatRepo: chatRepo,
    notificationRepo: notificationRepo,
    subscriptionRepo: subscriptionRepo,
  ));
}

class KonektaApp extends StatelessWidget {
  final Session session;
  final ApiClient api;
  final AuthRepository authRepo;
  final ProfileRepository profileRepo;
  final ChatRepository chatRepo;
  final NotificationRepository notificationRepo;
  final SubscriptionRepository subscriptionRepo;
  const KonektaApp({
    super.key,
    required this.session,
    required this.api,
    required this.authRepo,
    required this.profileRepo,
    required this.chatRepo,
    required this.notificationRepo,
    required this.subscriptionRepo,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      api: api,
      authRepo: authRepo,
      profileRepo: profileRepo,
      chatRepo: chatRepo,
      notificationRepo: notificationRepo,
      subscriptionRepo: subscriptionRepo,
      child: MaterialApp(
        title: 'Konekta',
        debugShowCheckedModeBanner: false,
        theme: KonektaTheme.light,
        home: const KonektaSplashScreen(),
      ),
    );
  }
}
