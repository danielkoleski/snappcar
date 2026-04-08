import 'package:flutter_test/flutter_test.dart';

import 'package:snappcar/features/maintenance/data/models/maintenance_record_model.dart';

void main() {
  group('MaintenanceRecord', () {
    test('fromJson maps all fields correctly', () {
      final json = {
        'id': 'm1',
        'vehicle_id': 'v1',
        'title': 'Troca de óleo',
        'description': 'Óleo 5W30 semissintético',
        'performed_at': '2024-03-15',
        'next_due_at': '2024-09-15',
        'next_due_km': 55000,
        'cost_brl': 180.00,
        'workshop_name': 'Auto Center Silva',
        'invoice_id': null,
        'created_at': '2024-03-15T10:00:00.000Z',
        'updated_at': '2024-03-15T10:00:00.000Z',
      };

      final record = MaintenanceRecord.fromJson(json);

      expect(record.id, equals('m1'));
      expect(record.title, equals('Troca de óleo'));
      expect(record.costBrl, equals(180.00));
      expect(record.nextDueKm, equals(55000));
      expect(record.workshopName, equals('Auto Center Silva'));
      expect(record.invoiceId, isNull);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'm2',
        'vehicle_id': 'v1',
        'title': 'Alinhamento',
        'description': null,
        'performed_at': '2024-01-10',
        'next_due_at': null,
        'next_due_km': null,
        'cost_brl': null,
        'workshop_name': null,
        'invoice_id': null,
        'created_at': '2024-01-10T09:00:00.000Z',
        'updated_at': '2024-01-10T09:00:00.000Z',
      };

      final record = MaintenanceRecord.fromJson(json);

      expect(record.description, isNull);
      expect(record.nextDueAt, isNull);
      expect(record.nextDueKm, isNull);
      expect(record.costBrl, isNull);
      expect(record.workshopName, isNull);
    });

    test('toJson round-trip preserves data', () {
      final original = MaintenanceRecord(
        id: 'm1',
        vehicleId: 'v1',
        title: 'Revisão',
        performedAt: DateTime(2024, 5, 1),
        createdAt: DateTime(2024, 5, 1),
        updatedAt: DateTime(2024, 5, 1),
      );

      final json = original.toJson();
      final restored = MaintenanceRecord.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
    });
  });

  group('MaintenanceTemplate', () {
    test('fromJson maps make/model nulls for universal templates', () {
      final json = {
        'id': 't1',
        'make': null,
        'model': null,
        'title': 'Troca de óleo e filtro',
        'interval_months': 6,
        'interval_km': 10000,
        'notes': 'Usar óleo especificado no manual',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final template = MaintenanceTemplate.fromJson(json);

      expect(template.make, isNull);
      expect(template.model, isNull);
      expect(template.intervalMonths, equals(6));
      expect(template.intervalKm, equals(10000));
    });
  });
}
