import 'package:supabase_flutter/supabase_flutter.dart';

import 'cake_repository.dart';
import 'local_cake_repository.dart';

class SupabaseCakeRepository implements CakeRepository {
  static const _table = 'cake_app_state';
  static const _pendingKey = 'sweet_studio_supabase_sync_pending';
  static const _timeout = Duration(seconds: 8);

  final LocalCakeRepository local;
  final SupabaseClient client;

  SupabaseCakeRepository(this.local, this.client);

  @override
  Future<Map<String, dynamic>> load() async {
    final cached = await local.load();
    final user = client.auth.currentUser;
    if (user == null) return cached;
    try {
      if (local.preferences.getBool(_pendingKey) == true) {
        await _upload(user.id, cached).timeout(_timeout);
        await local.preferences.setBool(_pendingKey, false);
        return cached;
      }
      final row = await client
          .from(_table)
          .select('data')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) {
        await _upload(user.id, cached).timeout(_timeout);
        return cached;
      }
      final remote = Map<String, dynamic>.from(row['data'] as Map? ?? {});
      await local.save(remote);
      return remote;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<void> save(
    Map<String, dynamic> snapshot, {
    bool requireRemote = false,
  }) async {
    final user = client.auth.currentUser;
    if (requireRemote) {
      if (user == null) {
        throw StateError('Sign in to Supabase before deleting an account.');
      }
      await _upload(user.id, snapshot).timeout(_timeout);
      await local.save(snapshot);
      await local.preferences.setBool(_pendingKey, false);
      return;
    }
    await local.save(snapshot);
    if (user == null) {
      await local.preferences.setBool(_pendingKey, true);
      return;
    }
    try {
      await _upload(user.id, snapshot).timeout(_timeout);
      await local.preferences.setBool(_pendingKey, false);
    } catch (_) {
      await local.preferences.setBool(_pendingKey, true);
    }
  }

  Future<void> _upload(String userId, Map<String, dynamic> snapshot) =>
      client.from(_table).upsert({
        'user_id': userId,
        'data': snapshot,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
}
