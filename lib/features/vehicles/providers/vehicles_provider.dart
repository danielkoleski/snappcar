import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/vehicle_model.dart';
import '../data/vehicle_repository.dart';

part 'vehicles_provider.g.dart';

@riverpod
Future<List<Vehicle>> vehiclesList(VehiclesListRef ref) {
  return ref.watch(vehicleRepositoryProvider).fetchAll();
}

@riverpod
Future<Vehicle> vehicleDetail(VehicleDetailRef ref, String vehicleId) {
  return ref.watch(vehicleRepositoryProvider).fetchById(vehicleId);
}

@riverpod
class VehiclesNotifier extends _$VehiclesNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create(Vehicle vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).create(vehicle),
    );
    ref.invalidate(vehiclesListProvider);
  }

  Future<void> update(Vehicle vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).update(vehicle),
    );
    ref.invalidate(vehiclesListProvider);
    ref.invalidate(vehicleDetailProvider(vehicle.id));
  }

  Future<void> delete(String vehicleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vehicleRepositoryProvider).delete(vehicleId),
    );
    ref.invalidate(vehiclesListProvider);
  }
}
