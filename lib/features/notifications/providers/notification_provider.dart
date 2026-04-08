import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notification_repository.dart';

part 'notification_provider.g.dart';

@riverpod
Future<bool> notificationsEnabled(NotificationsEnabledRef ref) {
  return ref.watch(notificationRepositoryProvider).isNotificationsEnabled();
}

@riverpod
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setEnabled(String token, {required bool enabled}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationRepositoryProvider)
          .setNotificationsEnabled(token, enabled: enabled),
    );
    ref.invalidate(notificationsEnabledProvider);
  }
}
