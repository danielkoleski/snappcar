import 'package:freezed_annotation/freezed_annotation.dart';

part 'mileage_entry_model.freezed.dart';
part 'mileage_entry_model.g.dart';

@freezed
class MileageEntry with _$MileageEntry {
  const factory MileageEntry({
    required String id,
    required String vehicleId,
    required int recordedKm,
    required DateTime recordedAt,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MileageEntry;

  factory MileageEntry.fromJson(Map<String, dynamic> json) =>
      _$MileageEntryFromJson(json);
}
