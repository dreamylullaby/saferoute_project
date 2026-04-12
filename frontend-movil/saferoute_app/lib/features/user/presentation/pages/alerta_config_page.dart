import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme.dart';
import '../../data/datasources/alerta_config_datasource.dart';
import '../../data/models/alerta_config_model.dart';

/// Pantalla de configuración de alertas por proximidad.
/// Permite al usuario ajustar el radio de alerta y activar/desactivar notificaciones.
class AlertaConfigPage extends StatefulWidget {
  const AlertaConfigPage({super.key});

  @override
  State<AlertaConfigPage> createState() => _AlertaConfigPageState();
}

class _AlertaConfigPageState extends State<AlertaConfigPage> {
  final _datasource = AlertaConfigDatasource();

  AlertaConfigModel? _config;
  bool _cargando   = true;
  bool _guardando  = false;
  String? _error;

  // Valores editables en pantalla
  late int    _radioMetros;
  late bool   _activo;

  @override
  void initState() {
    super.initState();
    _cargarConfig();
  }

  // ── Datos ──

  Future<void> _cargarConfig() async {
    try {
      final config = await _datasource.getConfig();
      if (!mounted) return;
      setState(() {
        _config      = config;
        _radioMetros = config.radioMetros;
        _activo      = config.activo;
        _cargando    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e.toString();
        _cargando = false;
        // Usar defaults si falla la carga
        _radioMetros = 500;
        _activo      = true;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final updated = await _datasource.saveConfig(
        radioMetros: _radioMetros,
        activo:      _activo,
      );
      if (!mounted) return;
      setState(() { _config = updated; _guardando = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: AppColors.zonaSegura,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── GPS ──

  Future<void> _probarAlertas() async {
    try {
      final permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de ubicación para las alertas'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final alertas = await _datasource.getAlertasCercanas(
        latitud:  pos.latitude,
        longitud: pos.longitude,
      );

      if (!mounted) return;
      _mostrarResultadoAlertas(alertas, pos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  void _mostrarResultadoAlertas(List<Map<String, dynamic>> alertas, Position pos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alertas.isEmpty
                  ? 'Sin reportes cercanos'
                  : '${alertas.length} reporte(s) en tu radio',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ubicación: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            ...alertas.take(5).map((a) => _AlertaTile(alerta: a)),
            if (alertas.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${alertas.length - 5} más...',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de alertas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Alertas activas',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                            Switch(
                              value: _activo,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setState(() => _activo = v),
                            ),
                          ],
                        ),
                        Text(
                          _activo
                              ? 'Recibirás alertas de hurtos cercanos a tu ubicación'
                              : 'Las alertas están desactivadas',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radio de alerta',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Te avisaremos si hay un hurto a menos de $_radioMetros metros',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSub,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('100m', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub)),
                            Expanded(
                              child: Slider(
                                value:    _radioMetros.toDouble(),
                                min:      100,
                                max:      5000,
                                divisions: 49,
                                activeColor:   AppColors.primary,
                                inactiveColor: AppColors.border,
                                label: '${_radioMetros}m',
                                onChanged: _activo
                                    ? (v) => setState(() => _radioMetros = v.round())
                                    : null,
                              ),
                            ),
                            Text('5km', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub)),
                          ],
                        ),
                        Center(
                          child: Text(
                            '$_radioMetros metros',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width:  20,
                              child:  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Guardar configuración'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _probarAlertas,
                      icon:  const Icon(Icons.location_on_outlined),
                      label: const Text('Ver alertas cercanas ahora'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar la configuración guardada. Usando valores por defecto.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ── Widgets auxiliares ──

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _AlertaTile extends StatelessWidget {
  final Map<String, dynamic> alerta;
  const _AlertaTile({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final distancia = (alerta['distancia_metros'] as num?)?.toStringAsFixed(0) ?? '?';
    final tipo      = alerta['tipo_hurto'] ?? 'hurto';
    final barrio    = alerta['barrio_ingresado'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.riesgoMedio, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$tipo en $barrio',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMain),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${distancia}m',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
