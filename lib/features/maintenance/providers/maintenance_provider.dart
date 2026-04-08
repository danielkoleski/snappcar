import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicles/providers/vehicles_provider.dart';
import '../data/maintenance_repository.dart';
import '../data/models/maintenance_record_model.dart';

part 'maintenance_provider.g.dart';

@riverpod
Future<List<MaintenanceRecord>> maintenanceList(
  MaintenanceListRef ref,
  String vehicleId,
) {
  return ref
      .watch(maintenanceRepositoryProvider)
      .fetchByVehicle(vehicleId);
}

@riverpod
Future<int> healthScore(HealthScoreRef ref, String vehicleId) async {
  final vehicleAsync = await ref.watch(vehicleDetailProvider(vehicleId).future);
  final records = await ref
      .watch(maintenanceRepositoryProvider)
      .fetchByVehicle(vehicleId);

  if (records.isEmpty) return 100;

  final overdue = await ref
      .watch(maintenanceRepositoryProvider)
      .fetchOverdue(vehicleId, vehicleAsync.odometer);

  final score =
      ((records.length - overdue.length) / records.length * 100).round();
  return score.clamp(0, 100);
}

@riverpod
class MaintenanceNotifier extends _$MaintenanceNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create(MaintenanceRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).create(record),
    );
    ref.invalidate(maintenanceListProvider(record.vehicleId));
    ref.invalidate(healthScoreProvider(record.vehicleId));
  }

  Future<void> update(MaintenanceRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).update(record),
    );
    ref.invalidate(maintenanceListProvider(record.vehicleId));
    ref.invalidate(healthScoreProvider(record.vehicleId));
  }

  Future<void> delete(String id, String vehicleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).delete(id),
    );
    ref.invalidate(maintenanceListProvider(vehicleId));
    ref.invalidate(healthScoreProvider(vehicleId));
  }
}
