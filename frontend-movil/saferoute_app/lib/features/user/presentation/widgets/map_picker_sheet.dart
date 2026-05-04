import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/app_theme.dart';

/// Bottom sheet con mapa para seleccionar ubicación del incidente.
class MapPickerSheet {
  MapPickerSheet._();

  /// Muestra el selector de mapa y retorna el punto seleccionado o null.
  static Future<LatLng?> show(BuildContext context) async {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyle = isDark
        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$token'
        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$token';

    LatLng centro = const LatLng(1.2136, -77.2811);
    try {
      final pos = await Geolocator.getCurrentPosition();
      centro = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    LatLng? puntoSeleccionado;
    final mapController = MapController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(children: [
                const Icon(Icons.touch_app_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Toca el mapa para marcar el lugar del incidente',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                )),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSub),
                  tooltip: 'Cancelar',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: 15,
                  onTap: (_, punto) => setModal(() => puntoSeleccionado = punto),
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapStyle,
                    userAgentPackageName: 'com.saferoute.app',
                  ),
                  if (puntoSeleccionado != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: puntoSeleccionado!,
                        width: 40, height: 40,
                        child: const Icon(Icons.location_pin,
                            color: AppColors.error, size: 40),
                      ),
                    ]),
                  // Punto de ubicación del usuario
                  MarkerLayer(markers: [
                    Marker(
                      point: centro,
                      width: 22, height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8, spreadRadius: 3,
                          )],
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: puntoSeleccionado == null
                      ? null
                      : () => Navigator.pop(ctx),
                  child: const Text('Confirmar ubicación'),
                ),
              ),
            ),
          ]),
        ),
      ),
    );

    return puntoSeleccionado;
  }
}
