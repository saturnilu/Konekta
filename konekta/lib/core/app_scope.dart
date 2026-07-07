import 'package:flutter/material.dart';
import 'api_client.dart';
import 'session.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/subscription_repository.dart';

/// Inherited widget that exposes [Session], [ApiClient], and the
/// pre-built repositories to the widget tree.
class AppScope extends InheritedWidget {
  final Session session;
  final ApiClient api;
  final bool loading;
  final String? error;
  final AuthRepository authRepo;
  final ProfileRepository profileRepo;
  final ChatRepository chatRepo;
  final NotificationRepository notificationRepo;
  final SubscriptionRepository subscriptionRepo;

  const AppScope({
    super.key,
    required this.session,
    required this.api,
    this.loading = false,
    this.error,
    required this.authRepo,
    required this.profileRepo,
    required this.chatRepo,
    required this.notificationRepo,
    required this.subscriptionRepo,
    required super.child,
  });

  /// Role of the current logged-in user ('influencer' or 'brand')
  String get role => session.role ?? 'influencer';

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  /// Runs a future and returns a `Result` with loading/error states.
  /// The caller is responsible for using the returned loading/error values
  /// (typically via a StatefulWidget that calls `setState` after awaiting).
  Future<T> run<T>(Future<T> Function() task) async {
    return task();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      session != oldWidget.session || api != oldWidget.api || loading != oldWidget.loading || error != oldWidget.error;
}
