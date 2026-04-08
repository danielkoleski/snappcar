import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mileage_repository.dart';
import '../data/models/mileage_entry_model.dart';

part 'mileage_provider.g.dart';

@riverpod
Future<List<MileageEntry>> mileageList(
  MileageListRef ref,
  String vehicleId,
) {
  return ref.watch(mileageRepositoryProvider).fetchByVehicle(vehicleId);
}

@riverpod
class MileageNotifier extends _$MileageNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create(MileageEntry entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mileageRepositoryProvider).create(entry),
    );
    ref.invalidate(mileageListProvider(entry.vehicleId));
  }
}
