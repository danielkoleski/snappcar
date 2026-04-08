import 'package:flutter_test/flutter_test.dart';

import 'package:snappcar/features/mileage/data/models/mileage_entry_model.dart';

void main() {
  group('MileageEntry', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'me1',
        'vehicle_id': 'v1',
        'recorded_km': 45000,
        'recorded_at': '2024-04-01',
        'notes': 'Abasteci depois',
        'created_at': '2024-04-01T08:00:00.000Z',
        'updated_at': '2024-04-01T08:00:00.000Z',
      };

      final entry = MileageEntry.fromJson(json);

      expect(entry.id, equals('me1'));
      expect(entry.recordedKm, equals(45000));
      expect(entry.notes, equals('Abasteci depois'));
    });

    test('fromJson handles null notes', () {
      final json = {
        'id': 'me2',
        'vehicle_id': 'v1',
        'recorded_km': 50000,
        'recorded_at': '2024-05-01',
        'notes': null,
        'created_at': '2024-05-01T00:00:00.000Z',
        'updated_at': '2024-05-01T00:00:00.000Z',
      };

      final entry = MileageEntry.fromJson(json);

      expect(entry.notes, isNull);
    });

    test('toJson round-trip preserves data', () {
      final original = MileageEntry(
        id: 'me3',
        vehicleId: 'v1',
        recordedKm: 60000,
        recordedAt: DateTime(2024, 6, 1),
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );

      final json = original.toJson();
      final restored = MileageEntry.fromJson(json);

      expect(restored.recordedKm, equals(original.recordedKm));
      expect(restored.vehicleId, equals(original.vehicleId));
    });
  });
}
