import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../maintenance/data/models/maintenance_record_model.dart';
import 'models/vehicle_model.dart';

part 'vehicle_repository.g.dart';

@riverpod
VehicleRepository vehicleRepository(VehicleRepositoryRef ref) {
  return SupabaseVehicleRepository(Supabase.instance.client);
}

abstract class VehicleRepository {
  Future<List<Vehicle>> fetchAll();
  Future<Vehicle> fetchById(String id);
  Future<Vehicle> create(Vehicle vehicle);
  Future<Vehicle> update(Vehicle vehicle);
  Future<void> delete(String id);
  Future<String> uploadPhoto(String vehicleId, File imageFile);
}

class SupabaseVehicleRepository implements VehicleRepository {
  SupabaseVehicleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Vehicle>> fetchAll() async {
    final response = await _client
        .from('vehicles')
        .select()
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Vehicle> fetchById(String id) async {
    final response =
        await _client.from('vehicles').select().eq('id', id).single();
    return Vehicle.fromJson(response);
  }

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    final data = vehicle.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final response =
        await _client.from('vehicles').insert(data).select().single();
    final created = Vehicle.fromJson(response);

    // Copy matching maintenance_templates → maintenance_records
    await _seedMaintenanceFromTemplates(created);

    return created;
  }

  @override
  Future<Vehicle> update(Vehicle vehicle) async {
    final data = vehicle.toJson()
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _client
        .from('vehicles')
        .update(data)
        .eq('id', vehicle.id)
        .select()
        .single();
    return Vehicle.fromJson(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }

  @override
  Future<String> uploadPhoto(String vehicleId, File imageFile) async {
    final uid = _client.auth.currentUser!.id;
    final fileName = '${const Uuid().v4()}.jpg';
    final path = '$uid/$vehicleId/$fileName';

    await _client.storage
        .from(AppConstants.vehiclePhotosBucket)
        .upload(path, imageFile);

    final signedUrl = await _client.storage
        .from(AppConstants.vehiclePhotosBucket)
        .createSignedUrl(path, AppConstants.storageSignedUrlExpirySeconds);

    // Persist the storage path (not the signed URL) in the DB
    await _client
        .from('vehicles')
        .update({'photo_url': path})
        .eq('id', vehicleId);

    return signedUrl;
  }

  /// Seeds maintenance_records from matching maintenance_templates.
  Future<void> _seedMaintenanceFromTemplates(Vehicle vehicle) async {
    final templates = await _client
        .from('maintenance_templates')
        .select()
        .or('make.is.null,make.eq.${vehicle.make}')
        .or('model.is.null,model.eq.${vehicle.model}');

    if ((templates as List<dynamic>).isEmpty) return;

    final now = DateTime.now();
    final records = templates.map((t) {
      final template =
          MaintenanceTemplate.fromJson(t as Map<String, dynamic>);
      final nextDueAt = template.intervalMonths != null
          ? DateTime(
              now.year,
              now.month + template.intervalMonths!,
              now.day,
            )
          : null;
      final nextDueKm = template.intervalKm != null
          ? vehicle.odometer + template.intervalKm!
          : null;

      return {
        'vehicle_id': vehicle.id,
        'title': template.title,
        'description': template.notes,
        'performed_at': now.toIso8601String().substring(0, 10),
        'next_due_at': nextDueAt?.toIso8601String().substring(0, 10),
        'next_due_km': nextDueKm,
      };
    }).toList();

    await _client.from('maintenance_records').insert(records);
  }
}
