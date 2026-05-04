import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../services/auth_storage.dart';
import '../../data/datasources/reporte_mapa_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../providers/mapa_notifier.dart';
import '../providers/map_notif_service.dart';
import '../providers/inactivity_service.dart';
import '../widgets/map_app_bar.dart';
import '../widgets/map_legend.dart';
import '../widgets/map_floating_buttons.dart';
import '../widgets/reporte_detail_sheet.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/heatmap_layer.dart';
import '../widgets/permission_modal.dart';

/// Mapa interactivo de incidentes de hurto.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});
  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _mapController = MapController();

  late final MapaNotifier _notifier;
  late final MapNotifService _notifService;
  late final InactivityService _inactivityService;
  StreamSubscription<LatLng>? _navSub;
  StreamSubscription<int>? _nuevosSub;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _notifier = MapaNotifier(ReporteMapaDatasource());

    _notifService = MapNotifService(
      messengerKey: _messengerKey,
      onNavigateToReport: (punto) => _mapController.move(punto, 16),
    );
    _notifService.initialize();

    _inactivityService = InactivityService(
      timeout: Duration(minutes: AuthStorage.inactivityTimeoutMinutes),
      onTimeout: _cerrarSesion,
    );

    _navSub = _notifier.navegacionStream.listen(
      (punto) => _mapController.move(punto, 16),
    );

    _nuevosSub = _notifier.nuevosReportesStream.listen((cantidad) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '$cantidad nuevo(s) reporte(s) cargado(s)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    });

    _obtenerUbicacion();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PermissionModals.mostrarSiNecesario(context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Re-verificar permisos al volver de configuración del sistema o perfil
      PermissionModals.mostrarSiNecesario(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navSub?.cancel();
    _nuevosSub?.cancel();
    _notifier.dispose();
    _notifService.dispose();
    _inactivityService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_userLocation!, 14);
    } catch (_) {}
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    await UserRemoteDatasource().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _resetInactivity() {
    AuthStorage.refreshActivity();
    _inactivityService.reset();
  }

  Color _colorTipo(String tipo) => switch (tipo) {
    'atraco'     => AppColors.hurtoAtraco,
    'raponazo'   => AppColors.hurtoRaponazo,
    'fleteo'     => AppColors.hurtoFleteo,
    'cosquilleo' => AppColors.hurtoCosquilleo,
    _            => AppColors.primary,
  };

  IconData _iconoTipo(String tipo) => switch (tipo) {
    'atraco'     => Icons.warning_rounded,
    'raponazo'   => Icons.directions_run,
    'fleteo'     => Icons.motorcycle,
    'cosquilleo' => Icons.back_hand_outlined,
    _            => Icons.location_on,
  };

  @override
  Widget build(BuildContext context) {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';

    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Consumer<MapaNotifier>(
        builder: (context, notifier, _) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _resetInactivity,
            onPanDown: (_) => _resetInactivity(),
            child: ScaffoldMessenger(
              key: _messengerKey,
              child: Scaffold(
                key: _scaffoldKey,
                drawer: FilterDrawer(
                  comunasSeleccionadas: notifier.comunasSeleccionadas,
                  corregimientosSeleccionados: notifier.corregimientosSeleccionados,
                  franjasSeleccionadas: notifier.franjasSeleccionadas,
                  tiposSeleccionados: notifier.tiposSeleccionados,
                  fechaDesde: notifier.fechaDesde,
                  fechaHasta: notifier.fechaHasta,
                  conteoFiltros: notifier.conteoFiltros,
                  hayFiltros: notifier.hayFiltros,
                  modoRural: notifier.modoRural,
                  onModoRuralChanged: (v) => notifier.setModoRural(v),
                  onFechaDesdeChanged: (d) => notifier.fechaDesde = d,
                  onFechaHastaChanged: (d) => notifier.fechaHasta = d,
                  onAplicar: () {
                    notifier.aplicarFiltros();
                    _messengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          notifier.hayFiltros
                              ? '${notifier.conteoFiltros} filtro(s) aplicado(s)'
                              : 'Filtros limpiados',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onRestablecer: notifier.limpiarFiltros,
                  onCerrarSesion: _cerrarSesion,
                  onPerfil: () async {
                    Navigator.pop(context); // cerrar drawer
                    await Navigator.pushNamed(context, '/perfil');
                    // Re-verificar permisos al volver del perfil
                    if (mounted) PermissionModals.mostrarSiNecesario(context);
                  },
                  onEstadisticas: () {
                    Navigator.pop(context); // cerrar drawer
                    Navigator.pushNamed(context, '/estadisticas');
                  },
                  onMisReportes: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/mis-reportes');
                  },
                ),
                body: notifier.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: LatLng(1.2136, -77.2811),
                            initialZoom: 14, minZoom: 10, maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              key: ValueKey('tiles_${darkModeNotifier.value}'),
                              urlTemplate: darkModeNotifier.value
                                  ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$token'
                                  : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$token',
                              userAgentPackageName: 'com.saferoute.app',
                            ),
                            if (notifier.modoCalor)
                              HeatmapLayer(
                                points: notifier.buildHeatmapPoints(),
                                radius: 35, maxOpacity: 0.55, blur: 20,
                              ),
                            if (!notifier.modoCalor)
                              MarkerLayer(
                                markers: notifier.filtrados.map((r) => Marker(
                                  point: LatLng(r.latitud, r.longitud),
                                  width: 36, height: 36,
                                  child: GestureDetector(
                                    onTap: () => ReporteDetailSheet.show(context, r),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _colorTipo(r.tipoHurto),
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2))],
                                      ),
                                      child: Icon(_iconoTipo(r.tipoHurto),
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            // Indicador de ubicación del usuario (siempre encima)
                            if (_userLocation != null)
                              MarkerLayer(markers: [
                                Marker(
                                  point: _userLocation!,
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
                        MapAppBar(
                          hayFiltros: notifier.hayFiltros,
                          conteoFiltros: notifier.conteoFiltros,
                          totalReportes: notifier.filtrados.length,
                          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Positioned(
                          bottom: 90 + MediaQuery.of(context).padding.bottom, left: 16,
                          child: MapLegend(modoCalor: notifier.modoCalor),
                        ),
                        MapFloatingButtons(
                          modoCalor: notifier.modoCalor,
                          isDark: darkModeNotifier.value,
                          onToggleCalor: notifier.toggleModoCalor,
                          onToggleDark: () {
                            darkModeNotifier.value = !darkModeNotifier.value;
                            // No usar setState — el ValueNotifier y el key del TileLayer
                            // se encargan de actualizar el mapa sin reconstruir el Scaffold
                            (context as Element).markNeedsBuild();
                          },
                          onMiUbicacion: _obtenerUbicacion,
                          onRegistrar: () => Navigator.pushNamed(context, '/reportar'),
                        ),
                      ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
