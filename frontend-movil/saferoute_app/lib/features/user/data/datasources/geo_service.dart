import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de geocodificación usando Mapbox API.
class GeoService {
  GeoService(this._mapboxToken);

  final String _mapboxToken;

  /// Geocodificación inversa: coordenadas → dirección.
  Future<String> geocodificarInverso(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
      '?access_token=$_mapboxToken&language=es&limit=1&types=address',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data     = jsonDecode(res.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final f       = features[0];
          final texto   = f['text'] as String? ?? '';
          final numero  = (f['address'] as String? ?? '').replaceAll(' ', '-');
          return numero.isNotEmpty ? '$texto #$numero' : texto;
        }
      }
    } catch (_) {}
    return '';
  }

  /// Geocodificación directa: texto → coordenadas (lat, lng).
  /// Retorna null si no encuentra resultados.
  Future<({double lat, double lng})?> geocodificarDireccion(String query) async {
    final encoded = Uri.encodeComponent(query.trim());
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
      '?access_token=$_mapboxToken&language=es&limit=1&types=address'
      '&proximity=-77.2811,1.2136',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final coords = features[0]['center'] as List;
          return (lat: (coords[1] as num).toDouble(), lng: (coords[0] as num).toDouble());
        }
      }
    } catch (_) {}
    return null;
  }

  /// Forward geocoding: texto → lista de sugerencias de dirección.
  Future<List<String>> buscarDirecciones(String query) async {
    final encoded = Uri.encodeComponent(query.trim());
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
      '?access_token=$_mapboxToken&language=es&limit=4&types=address'
      '&proximity=-77.2811,1.2136',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data     = jsonDecode(res.body);
        final features = data['features'] as List;
        return features.map<String>((f) {
          final texto  = f['text'] as String? ?? '';
          final numero = (f['address'] as String? ?? '').replaceAll(' ', '-');
          return numero.isNotEmpty ? '$texto #$numero' : texto;
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
