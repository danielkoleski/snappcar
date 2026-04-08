import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/mileage_entry_model.dart';

part 'mileage_repository.g.dart';

@riverpod
MileageRepository mileageRepository(MileageRepositoryRef ref) {
  return SupabaseMileageRepository(Supabase.instance.client);
}

abstract class MileageRepository {
  Future<List<MileageEntry>> fetchByVehicle(String vehicleId);
  Future<MileageEntry> create(MileageEntry entry);
  Future<bool> hasEntryForCurrentMonth(String vehicleId);
}

class SupabaseMileageRepository implements MileageRepository {
  SupabaseMileageRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MileageEntry>> fetchByVehicle(String vehicleId) async {
    final response = await _client
        .from('mileage_entries')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('recorded_at', ascending: true);
    return (response as List<dynamic>)
        .map((e) => MileageEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MileageEntry> create(MileageEntry entry) async {
    final data = entry.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _client
        .from('mileage_entries')
        .insert(data)
        .select()
        .single();
    return MileageEntry.fromJson(response);
  }

  @override
  Future<bool> hasEntryForCurrentMonth(String vehicleId) async {
    final now = DateTime.now();
    final firstOfMonth =
        DateTime(now.year, now.month).toIso8601String().substring(0, 10);
    final firstOfNext =
        DateTime(now.year, now.month + 1).toIso8601String().substring(0, 10);

    final response = await _client
        .from('mileage_entries')
        .select('id')
        .eq('vehicle_id', vehicleId)
        .gte('recorded_at', firstOfMonth)
        .lt('recorded_at', firstOfNext)
        .limit(1);
    return (response as List<dynamic>).isNotEmpty;
  }
}
