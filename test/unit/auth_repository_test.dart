import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snappcar/features/auth/data/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late SupabaseAuthRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = SupabaseAuthRepository(mockClient);
  });

  group('SupabaseAuthRepository', () {
    group('signInWithEmail', () {
      test('calls signInWithPassword with correct credentials', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(
            session: null,
            user: null,
          ),
        );

        await repository.signInWithEmail('test@test.com', 'password123!');

        verify(
          () => mockAuth.signInWithPassword(
            email: 'test@test.com',
            password: 'password123!',
          ),
        ).called(1);
      });

      test('propagates AuthException on failure', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthException('Invalid login credentials'),
        );

        expect(
          () => repository.signInWithEmail('bad@test.com', 'wrong'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUp', () {
      test('calls supabase signUp with full_name metadata', () async {
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => AuthResponse(session: null, user: null));

        await repository.signUp('new@test.com', 'Pass123!', 'João Silva');

        verify(
          () => mockAuth.signUp(
            email: 'new@test.com',
            password: 'Pass123!',
            data: {'full_name': 'João Silva'},
          ),
        ).called(1);
      });
    });

    group('signOut', () {
      test('calls supabase signOut', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(() => mockAuth.signOut()).called(1);
      });
    });
  });
}
