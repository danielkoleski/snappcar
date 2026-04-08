import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/vehicles/data/models/vehicle_model.dart';

part 'fipe_service.g.dart';

const _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

@riverpod
FipeService fipeService(FipeServiceRef ref) => FipeService();

class FipeService {
  Future<List<FipeMake>> fetchMakes() async {
    final response = await http.get(Uri.parse('$_baseUrl/carros/marcas'));
    _assertOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map(
          (e) => FipeMake(
            code: e['codigo'].toString(),
            name: _sanitizeString(e['nome'] as String),
          ),
        )
        .toList();
  }

  Future<List<FipeModel>> fetchModels(String makeCode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/carros/marcas/$makeCode/modelos'),
    );
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['modelos'] as List<dynamic>;
    return list
        .map(
          (e) => FipeModel(
            code: e['codigo'].toString(),
            name: _sanitizeString(e['nome'] as String),
          ),
        )
        .toList();
  }

  Future<List<FipeYear>> fetchYears(
    String makeCode,
    String modelCode,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/carros/marcas/$makeCode/modelos/$modelCode/anos',
      ),
    );
    _assertOk(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map(
          (e) => FipeYear(
            code: e['codigo'].toString(),
            name: _sanitizeString(e['nome'] as String),
          ),
        )
        .toList();
  }

  void _assertOk(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        'FIPE API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Sanitise FIPE string responses before storing in DB.
  String _sanitizeString(String value) => value.trim();
}
