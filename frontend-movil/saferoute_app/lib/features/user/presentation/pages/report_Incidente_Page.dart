import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../../../../services/auth_storage.dart';

class ReportIncidentePage extends StatefulWidget {
  const ReportIncidentePage({super.key});
  @override
  State<ReportIncidentePage> createState() => _ReportIncidentePageState();
}

class _ReportIncidentePageState extends State<ReportIncidentePage> {
  final _formKey             = GlobalKey<FormState>();
  final fechaController      = TextEditingController();
  final direccionController  = TextEditingController();
  final barrioController     = TextEditingController();
  final descripcionController = TextEditingController();

  bool isLoading = false;
  double? _latitud;
  double? _longitud;

  // Autocomplete barrio
  List<String> _sugerenciasBarrio    = [];
  Timer?        _debounceBarrio;
  bool          _barrioSeleccionado  = false;

  // Autocomplete dirección
  List<String> _sugerenciasDireccion = [];
  Timer?        _debounceDireccion;

  String? tipoReportante;
  String? franjaHoraria;
  String? tipoHurto;
  String? objetoHurtado;
  String? numeroAgresores;

  final _tiposReportante = ['victima', 'testigo'];
  final _franjasHorarias = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  final _tiposHurto      = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];
  final _objetosHurtados = ['celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos'];
  final _numAgresores    = ['1', '2', '3+', 'desconocido'];

  @override
  void dispose() {
    _debounceBarrio?.cancel();
    _debounceDireccion?.cancel();
    super.dispose();
  }

  // ── Fecha ──────────────────────────────────────────────────────────────────

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      fechaController.text = picked.toIso8601String().split('T')[0];
    }
  }

  // ── Geocodificación inversa — solo dirección corta ─────────────────────────

  Future<String> _geocodificarInverso(double lat, double lng) async {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    // types=address limita a solo direcciones, sin ciudad/país
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
      '?access_token=$token&language=es&limit=1&types=address',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data     = jsonDecode(res.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          // text = nombre de la calle, address = número
          final f       = features[0];
          final texto   = f['text'] as String? ?? '';
          final numero  = f['address'] as String? ?? '';
          return numero.isNotEmpty ? '$texto $numero' : texto;
        }
      }
    } catch (_) {}
    return '';
  }

  // ── Autocomplete dirección (Mapbox forward geocoding) ─────────────────────

  void _onDireccionChanged(String valor) {
    _debounceDireccion?.cancel();
    if (valor.trim().length < 4) {
      setState(() => _sugerenciasDireccion = []);
      return;
    }
    _debounceDireccion = Timer(const Duration(milliseconds: 400), () async {
      final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
      final query = Uri.encodeComponent(valor.trim());
      final url   = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
        '?access_token=$token&language=es&limit=4&types=address'
        '&proximity=-77.2811,1.2136', // centrado en Pasto
      );
      try {
        final res = await http.get(url);
        if (res.statusCode == 200 && mounted) {
          final data     = jsonDecode(res.body);
          final features = data['features'] as List;
          final sugs     = features.map<String>((f) {
            final texto  = f['text'] as String? ?? '';
            final numero = f['address'] as String? ?? '';
            return numero.isNotEmpty ? '$texto $numero' : texto;
          }).toList();
          setState(() => _sugerenciasDireccion = sugs);
        }
      } catch (_) {}
    });
  }

  // ── Autocomplete barrio (backend) ──────────────────────────────────────────

  void _onBarrioChanged(String valor) {
    _debounceBarrio?.cancel();
    setState(() => _barrioSeleccionado = false);
    if (valor.trim().length < 2) {
      setState(() => _sugerenciasBarrio = []);
      return;
    }
    _debounceBarrio = Timer(const Duration(milliseconds: 350), () async {
      try {
        final token = await AuthStorage.getToken();
        final uri   = Uri.parse(
          'http://localhost:3000/api/reportes/barrios'
        ).replace(queryParameters: {'q': valor.trim()});
        final res = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
        });
        if (res.statusCode == 200 && mounted) {
          final data = jsonDecode(res.body);
          final lista = (data['data'] as List)
              .map<String>((e) => e['barrio'] as String)
              .toList();
          setState(() => _sugerenciasBarrio = lista);
        }
      } catch (_) {}
    });
  }

  // ── Selector de ubicación en mapa ──────────────────────────────────────────

  Future<void> _abrirSelectorMapa() async {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    LatLng centro = const LatLng(1.2136, -77.2811);
    try {
      final pos = await Geolocator.getCurrentPosition();
      centro = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    LatLng? puntoSeleccionado;
    final mapController = MapController();
    if (!mounted) return;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                const Icon(Icons.touch_app_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Toca el mapa para marcar el lugar del incidente',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                )),
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
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v12'
                        '/tiles/{z}/{x}/{y}?access_token=$token',
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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

    if (puntoSeleccionado != null) {
      setState(() => isLoading = true);
      final dir = await _geocodificarInverso(
          puntoSeleccionado!.latitude, puntoSeleccionado!.longitude);
      if (!mounted) return;
      setState(() {
        _latitud  = puntoSeleccionado!.latitude;
        _longitud = puntoSeleccionado!.longitude;
        if (dir.isNotEmpty) {
          direccionController.text = dir;
          _sugerenciasDireccion    = [];
        }
        isLoading = false;
      });
    }
  }

  // ── Enviar reporte ─────────────────────────────────────────────────────────

  void enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      mostrarError(context, 'Debes seleccionar la ubicación del incidente en el mapa.');
      return;
    }
    setState(() => isLoading = true);
    try {
      final token  = await AuthStorage.getToken();
      final userId = await AuthStorage.getUserId();
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/reportes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario_id':       userId,
          'tipo_reportante':  tipoReportante,
          'fecha_incidente':  fechaController.text,
          'franja_horaria':   franjaHoraria,
          'latitud':          _latitud,
          'longitud':         _longitud,
          'direccion':        direccionController.text.trim(),
          'barrio_ingresado': barrioController.text.trim(),
          'tipo_hurto':       tipoHurto,
          'descripcion':      descripcionController.text.trim(),
          'objeto_hurtado':   objetoHurtado,
          'numero_agresores': numeroAgresores,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        mostrarExito(context, 'Tu reporte fue enviado exitosamente.',
            alCerrar: () => Navigator.pop(context));
      } else {
        final data = jsonDecode(res.body);
        mostrarError(context, data['message'] ?? 'Error al enviar reporte');
      }
    } catch (_) {
      if (!mounted) return;
      mostrarError(context, 'Error de conexión. Verifica tu internet e intenta de nuevo.');
    }
    setState(() => isLoading = false);
  }

  // ── Validaciones ───────────────────────────────────────────────────────────

  String? _validarDireccion(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    final s = v.trim();
    if (s.length < 5)
      return 'La dirección debe tener al menos 5 caracteres';
    if (!RegExp(r'\d').hasMatch(s))
      return 'Incluye un número en la dirección (ej: Calle 15 22B)';
    if (RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s#\-\.]').hasMatch(s))
      return 'Solo letras, números, #, - y puntos';
    return null;
  }

  String? _validarBarrio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    if (s.length < 3)
      return 'Mínimo 3 caracteres';
    if (RegExp(r'\d').hasMatch(s))
      return 'El barrio no debe contener números';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(s))
      return 'Solo letras y espacios';
    return null;
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String Function(T)? display,
    bool required = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      menuMaxHeight: 260,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSub),
        prefixIcon: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
      ),
      items: items.map((e) {
        final texto = display != null ? display(e) : e.toString();
        return DropdownMenuItem(
          value: e,
          child: Text(texto,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMain)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Campo obligatorio' : null : null,
    );
  }

  Widget _listaSugerencias(List<String> items, void Function(String) onSelect) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((s) => InkWell(
          onTap: () => onSelect(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.textSub),
              const SizedBox(width: 8),
              Expanded(child: Text(s,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMain))),
            ]),
          ),
        )).toList(),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar hurto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [

            _dropdown<String>(
              label: '¿Eres víctima o testigo?',
              value: tipoReportante,
              items: _tiposReportante,
              display: (e) => e[0].toUpperCase() + e.substring(1),
              onChanged: (v) => setState(() => tipoReportante = v),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: fechaController,
              readOnly: true,
              onTap: _seleccionarFecha,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              decoration: InputDecoration(
                labelText: 'Fecha del incidente',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            _dropdown<String>(
              label: 'Franja horaria',
              value: franjaHoraria,
              items: _franjasHorarias,
              onChanged: (v) => setState(() => franjaHoraria = v),
            ),
            const SizedBox(height: 15),

            // ── Dirección con autocomplete ──
            TextFormField(
              controller: direccionController,
              onChanged: _onDireccionChanged,
              validator: _validarDireccion,
              decoration: InputDecoration(
                labelText: 'Dirección (opcional)',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                  tooltip: 'Buscar en el mapa',
                  onPressed: _abrirSelectorMapa,
                ),
              ),
            ),
            _listaSugerencias(_sugerenciasDireccion, (s) {
              setState(() {
                direccionController.text = s;
                _sugerenciasDireccion    = [];
              });
            }),
            const SizedBox(height: 6),

            if (_latitud != null)
              Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
                const SizedBox(width: 6),
                Text('Ubicación seleccionada en el mapa',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Color(0xFF22C55E))),
              ])
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _abrirSelectorMapa,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Buscar en el mapa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 15),

            // ── Barrio con autocomplete desde BD ──
            TextFormField(
              controller: barrioController,
              onChanged: _onBarrioChanged,
              validator: _validarBarrio,
              decoration: InputDecoration(
                labelText: 'Barrio donde ocurrió',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _barrioSeleccionado
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF22C55E), size: 20)
                    : null,
              ),
            ),
            _listaSugerencias(_sugerenciasBarrio, (s) {
              setState(() {
                barrioController.text = s;
                _sugerenciasBarrio    = [];
                _barrioSeleccionado   = true;
              });
            }),
            const SizedBox(height: 15),

            _dropdown<String>(
              label: 'Tipo de hurto',
              value: tipoHurto,
              items: _tiposHurto,
              display: (e) => e[0].toUpperCase() + e.substring(1),
              onChanged: (v) => setState(() => tipoHurto = v),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: objetoHurtado,
              menuMaxHeight: 260,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'Objeto hurtado (opcional)',
                labelStyle: GoogleFonts.inter(color: AppColors.textSub),
                prefixIcon: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary),
              ),
              items: _objetosHurtados
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.replaceAll('_', ' '),
                            style: GoogleFonts.inter(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => objetoHurtado = v),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: numeroAgresores,
              menuMaxHeight: 260,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'Número de agresores (opcional)',
                labelStyle: GoogleFonts.inter(color: AppColors.textSub),
                prefixIcon:
                    const Icon(Icons.people_outline, color: AppColors.primary),
              ),
              items: _numAgresores
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: GoogleFonts.inter(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => numeroAgresores = v),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: descripcionController,
              maxLength: 300,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : enviarReporte,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar reporte'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
