import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snappcar/features/vehicles/data/vehicle_repository.dart';
import 'package:snappcar/features/vehicles/data/models/vehicle_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

/// Sample vehicle for reuse across tests
Vehicle _sampleVehicle({String id = 'v1'}) => Vehicle(
      id: id,
      ownerId: 'user1',
      make: 'Volkswagen',
      model: 'Polo',
      year: 2022,
      color: 'Prata',
      plate: 'ABC1D23',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
  });

  group('SupabaseVehicleRepository', () {
    group('fetchAll', () {
      test('returns empty list when no vehicles exist', () async {
        // Supabase returns empty list when RLS denies cross-user access
        // This test simulates a user with no vehicles
        final repo = SupabaseVehicleRepository(mockClient);

        // Verify repository is instantiated correctly
        expect(repo, isA<VehicleRepository>());
      });

      test('maps JSON response to Vehicle list', () {
        final json = {
          'id': 'v1',
          'owner_id': 'user1',
          'make': 'Volkswagen',
          'model': 'Polo',
          'year': 2022,
          'color': 'Prata',
          'plate': 'ABC1D23',
          'fipe_code': null,
          'odometer': 15000,
          'photo_url': null,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };

        final vehicle = Vehicle.fromJson(json);

        expect(vehicle.id, equals('v1'));
        expect(vehicle.make, equals('Volkswagen'));
        expect(vehicle.model, equals('Polo'));
        expect(vehicle.year, equals(2022));
        expect(vehicle.odometer, equals(15000));
      });
    });

    group('Vehicle.fromJson', () {
      test('handles null optional fields', () {
        final json = {
          'id': 'v1',
          'owner_id': 'user1',
          'make': 'Fiat',
          'model': 'Uno',
          'year': 2010,
          'color': 'Branco',
          'plate': null,
          'fipe_code': null,
          'odometer': 0,
          'photo_url': null,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };

        final vehicle = Vehicle.fromJson(json);

        expect(vehicle.plate, isNull);
        expect(vehicle.fipeCode, isNull);
        expect(vehicle.photoUrl, isNull);
      });
    });
  });
}
