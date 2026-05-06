import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../services/auth_storage.dart';

/// Servicio de autocompletado de barrios (backend CIVICTRACKIO).
class AutocompleteService {
  AutocompleteService(this._baseUrl);

  final String _baseUrl;

  /// Busca barrios por coordenadas usando la función RPC del backend.
  /// Retorna {comuna, barrios} o null si no hay cobertura.
  Future<({int comuna, List<String> barrios})?> buscarBarriosPorCoordenadas(
      double lat, double lng) async {
    try {
      final token = await AuthStorage.getToken();
      final uri = Uri.parse('$_baseUrl/api/reportes/barrios-por-coordenadas')
          .replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          return (
            comuna: body['data']['comuna'] as int,
            barrios: (body['data']['barrios'] as List).cast<String>(),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Busca barrios por texto parcial (autocomplete Caso B).
  Future<List<String>> buscarBarriosPorTexto(String texto) async {
    try {
      final token = await AuthStorage.getToken();
      final uri = Uri.parse('$_baseUrl/api/reportes/barrios')
          .replace(queryParameters: {'q': texto});
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List).map<String>((e) => e['barrio'] as String).toList();
      }
    } catch (_) {}
    return [];
  }
}
