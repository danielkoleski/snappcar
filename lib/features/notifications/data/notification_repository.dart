import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'notification_repository.g.dart';

@riverpod
NotificationRepository notificationRepository(
  NotificationRepositoryRef ref,
) {
  return SupabaseNotificationRepository(Supabase.instance.client);
}

abstract class NotificationRepository {
  Future<void> upsertToken(String token);
  Future<void> deleteToken(String token);
  Future<void> setNotificationsEnabled(
    String token, {
    required bool enabled,
  });
  Future<bool> isNotificationsEnabled();
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Future<void> upsertToken(String token) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client.from('device_tokens').upsert(
      {
        'profile_id': uid,
        'token': token,
        'platform': _platform,
        'notifications_enabled': true,
      },
      onConflict: 'token',
    );
  }

  @override
  Future<void> deleteToken(String token) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }

  @override
  Future<void> setNotificationsEnabled(
    String token, {
    required bool enabled,
  }) async {
    await _client
        .from('device_tokens')
        .update({'notifications_enabled': enabled})
        .eq('token', token);
  }

  @override
  Future<bool> isNotificationsEnabled() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    final response = await _client
        .from('device_tokens')
        .select('notifications_enabled')
        .eq('profile_id', uid)
        .limit(1)
        .maybeSingle();

    return (response?['notifications_enabled'] as bool?) ?? false;
  }
}
