import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_record_model.freezed.dart';
part 'maintenance_record_model.g.dart';

@freezed
class MaintenanceRecord with _$MaintenanceRecord {
  const factory MaintenanceRecord({
    required String id,
    required String vehicleId,
    required String title,
    String? description,
    required DateTime performedAt,
    DateTime? nextDueAt,
    int? nextDueKm,
    double? costBrl,
    String? workshopName,
    String? invoiceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MaintenanceRecord;

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRecordFromJson(json);
}

@freezed
class MaintenanceTemplate with _$MaintenanceTemplate {
  const factory MaintenanceTemplate({
    required String id,
    String? make,
    String? model,
    required String title,
    int? intervalMonths,
    int? intervalKm,
    String? notes,
    required DateTime createdAt,
  }) = _MaintenanceTemplate;

  factory MaintenanceTemplate.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTemplateFromJson(json);
}
