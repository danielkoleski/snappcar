import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/maintenance_record_model.dart';

part 'maintenance_repository.g.dart';

@riverpod
MaintenanceRepository maintenanceRepository(MaintenanceRepositoryRef ref) {
  return SupabaseMaintenanceRepository(Supabase.instance.client);
}

abstract class MaintenanceRepository {
  Future<List<MaintenanceRecord>> fetchByVehicle(String vehicleId);
  Future<List<MaintenanceRecord>> fetchOverdue(
    String vehicleId,
    int currentOdometer,
  );
  Future<MaintenanceRecord> create(MaintenanceRecord record);
  Future<MaintenanceRecord> update(MaintenanceRecord record);
  Future<void> delete(String id);
}

class SupabaseMaintenanceRepository implements MaintenanceRepository {
  SupabaseMaintenanceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MaintenanceRecord>> fetchByVehicle(String vehicleId) async {
    final response = await _client
        .from('maintenance_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('performed_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MaintenanceRecord>> fetchOverdue(
    String vehicleId,
    int currentOdometer,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _client
        .from('maintenance_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .or(
          'next_due_at.lt.$today,'
          'next_due_km.lte.$currentOdometer',
        );
    return (response as List<dynamic>)
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MaintenanceRecord> create(MaintenanceRecord record) async {
    final data = record.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _client
        .from('maintenance_records')
        .insert(data)
        .select()
        .single();
    return MaintenanceRecord.fromJson(response);
  }

  @override
  Future<MaintenanceRecord> update(MaintenanceRecord record) async {
    final data = record.toJson()
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _client
        .from('maintenance_records')
        .update(data)
        .eq('id', record.id)
        .select()
        .single();
    return MaintenanceRecord.fromJson(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('maintenance_records').delete().eq('id', id);
  }
}
