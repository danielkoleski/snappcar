import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String ownerId,
    required String make,
    required String model,
    required int year,
    required String color,
    String? plate,
    String? fipeCode,
    @Default(0) int odometer,
    String? photoUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}

@freezed
class FipeMake with _$FipeMake {
  const factory FipeMake({
    required String code,
    required String name,
  }) = _FipeMake;

  factory FipeMake.fromJson(Map<String, dynamic> json) =>
      _$FipeMakeFromJson(json);
}

@freezed
class FipeModel with _$FipeModel {
  const factory FipeModel({
    required String code,
    required String name,
  }) = _FipeModel;

  factory FipeModel.fromJson(Map<String, dynamic> json) =>
      _$FipeModelFromJson(json);
}

@freezed
class FipeYear with _$FipeYear {
  const factory FipeYear({
    required String code,
    required String name,
  }) = _FipeYear;

  factory FipeYear.fromJson(Map<String, dynamic> json) =>
      _$FipeYearFromJson(json);
}
