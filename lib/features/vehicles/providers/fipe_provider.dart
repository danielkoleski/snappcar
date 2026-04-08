import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/services/fipe_service.dart';
import '../data/models/vehicle_model.dart';

part 'fipe_provider.g.dart';

@riverpod
Future<List<FipeMake>> fipeMakes(FipeMakesRef ref) {
  return ref.watch(fipeServiceProvider).fetchMakes();
}

@riverpod
Future<List<FipeModel>> fipeModels(FipeModelsRef ref, String makeCode) {
  return ref.watch(fipeServiceProvider).fetchModels(makeCode);
}

@riverpod
Future<List<FipeYear>> fipeYears(
  FipeYearsRef ref,
  String makeCode,
  String modelCode,
) {
  return ref.watch(fipeServiceProvider).fetchYears(makeCode, modelCode);
}
