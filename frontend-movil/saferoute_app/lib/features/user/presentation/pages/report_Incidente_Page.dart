import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../../../../services/auth_storage.dart';

/// Formulario de registro de incidente de hurto.
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

  // Almacena la fecha en ISO para enviar al backend
  String? _fechaISO;

  // Autocomplete barrio (modo texto libre — Caso B)
  List<String> _sugerenciasBarrio    = [];
  Timer?        _debounceBarrio;
  bool          _barrioSeleccionado  = false;
  final FocusNode _barrioFocus       = FocusNode();

  // Barrios por coordenadas (modo lista filtrable — Caso A)
  List<String> _barriosCoordenadas   = [];
  List<String> _barriosFiltrados     = [];
  int?         _comunaDetectada;
  bool         _sinCobertura         = false;
  final TextEditingController _filtroBusquedaController = TextEditingController();

  // Autocomplete dirección
  List<String> _sugerenciasDireccion = [];
  Timer?        _debounceDireccion;
  final FocusNode _direccionFocus    = FocusNode();

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

  /// Indica si estamos en modo lista filtrable (Caso A con barrios detectados)
  bool get _modoListaBarrios => _barriosCoordenadas.isNotEmpty && !_sinCobertura;

  @override
  void initState() {
    super.initState();
    _direccionFocus.addListener(() {
      if (!_direccionFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _sugerenciasDireccion = []);
        });
      }
    });
    _barrioFocus.addListener(() {
      if (!_barrioFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() {
            _sugerenciasBarrio = [];
            if (_modoListaBarrios) _barriosFiltrados = [];
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceBarrio?.cancel();
    _debounceDireccion?.cancel();
    _direccionFocus.dispose();
    _barrioFocus.dispose();
    _filtroBusquedaController.dispose();
    super.dispose();
  }

  // ── Fecha ──────────────────────────────────────────────────────────────────

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null) {
      _fechaISO = picked.toIso8601String().split('T')[0];
      fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // ── Normalización de direcciones colombianas ───────────────────────────────

  /// Normaliza una dirección de Mapbox al formato colombiano abreviado.
  /// Entrada: "Carrera 27 12-34" → Salida: "Cra 27 #12-34"
  String _normalizarDireccion(String texto, String numero) {
    if (texto.isEmpty) return '';

    String resultado = texto;

    // Abreviar tipos de vía
    final abreviaturas = {
      r'(?i)\bcarrera\b': 'Cra',
      r'(?i)\bcalle\b': 'Cl',
      r'(?i)\bdiagonal\b': 'Diag',
      r'(?i)\btransversal\b': 'Tv',
      r'(?i)\bavenida\b': 'Av',
    };

    for (final entry in abreviaturas.entries) {
      resultado = resultado.replaceAll(RegExp(entry.key), entry.value);
    }

    // Agregar número con formato #N1-N2
    if (numero.isNotEmpty) {
      // Si el número ya tiene guión (ej: "12-34"), agregar #
      if (numero.contains('-')) {
        resultado = '$resultado #$numero';
      } else {
        resultado = '$resultado #$numero';
      }
    }

    return resultado.trim();
  }

  // ── Geocodificación inversa ──────────────────────────────────────────────

  Future<String> _geocodificarInverso(double lat, double lng) async {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
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
          final f       = features[0];
          final texto   = f['text'] as String? ?? '';
          final numero  = (f['address'] as String? ?? '').replaceAll(' ', '-');
          return numero.isNotEmpty ? '$texto #$numero' : texto;
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
        '&proximity=-77.2811,1.2136',
      );
      try {
        final res = await http.get(url);
        if (res.statusCode == 200 && mounted) {
          final data     = jsonDecode(res.body);
          final features = data['features'] as List;
          final sugs     = features.map<String>((f) {
            final texto  = f['text'] as String? ?? '';
            final numero = (f['address'] as String? ?? '').replaceAll(' ', '-');
            return numero.isNotEmpty ? '$texto #$numero' : texto;
          }).toList();
          setState(() => _sugerenciasDireccion = sugs);
        }
      } catch (_) {}
    });
  }

  // ── Buscar barrios por coordenadas (Caso A) ───────────────────────────────

  Future<void> _buscarBarriosPorCoordenadas(double lat, double lng) async {
    try {
      final token = await AuthStorage.getToken();
      final uri = Uri.parse(
        'http://localhost:3000/api/reportes/barrios-por-coordenadas'
      ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        if (body['data'] != null) {
          final comuna  = body['data']['comuna'] as int;
          final barrios = (body['data']['barrios'] as List).cast<String>();
          setState(() {
            _comunaDetectada    = comuna;
            _barriosCoordenadas = barrios;
            _barriosFiltrados   = [];
            _sinCobertura       = false;
            barrioController.clear();
            _barrioSeleccionado = false;
            _filtroBusquedaController.clear();
          });
        } else {
          setState(() {
            _comunaDetectada    = null;
            _barriosCoordenadas = [];
            _barriosFiltrados   = [];
            _sinCobertura       = true;
            barrioController.clear();
            _barrioSeleccionado = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sinCobertura       = true;
          _barriosCoordenadas = [];
          _barriosFiltrados   = [];
          _comunaDetectada    = null;
        });
      }
    }
  }

  // ── Filtrar barrios localmente (Caso A) ────────────────────────────────────

  void _filtrarBarriosLocalmente(String texto) {
    if (texto.trim().isEmpty) {
      setState(() => _barriosFiltrados = []);
      return;
    }
    final lower = texto.trim().toLowerCase();
    final filtrados = _barriosCoordenadas
        .where((b) => b.toLowerCase().contains(lower))
        .take(8)
        .toList();
    setState(() => _barriosFiltrados = filtrados);
  }

  // ── Autocomplete barrio por texto (Caso B — sin coordenadas) ───────────────

  void _onBarrioChanged(String valor) {
    if (_modoListaBarrios) {
      _filtrarBarriosLocalmente(valor);
      setState(() => _barrioSeleccionado = false);
      return;
    }

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
      await _buscarBarriosPorCoordenadas(
        puntoSeleccionado!.latitude, puntoSeleccionado!.longitude);
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
          'fecha_incidente':  _fechaISO,
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
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    if (s.length < 5)
      return 'La dirección debe tener al menos 5 caracteres';
    if (!RegExp(r'\d').hasMatch(s))
      return 'Incluye un número en la dirección (ej: Cra 15 #22-10)';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return DropdownButtonFormField<T>(
      value: value,
      menuMaxHeight: 260,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: subColor),
        prefixIcon: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: textColor),
      items: items.map((e) {
        final texto = display != null ? display(e) : e.toString();
        return DropdownMenuItem(
          value: e,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(texto,
                style: GoogleFonts.inter(fontSize: 14, color: textColor)),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Campo obligatorio' : null : null,
    );
  }

  Widget _listaSugerencias(List<String> items, void Function(String) onSelect) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF475569) : AppColors.border),
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
              Icon(Icons.place_outlined, size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub),
              const SizedBox(width: 8),
              Expanded(child: Text(s,
                  style: GoogleFonts.inter(fontSize: 13,
                      color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain))),
            ]),
          ),
        )).toList(),
      ),
    );
  }

  /// Widget de lista filtrable para barrios detectados por coordenadas (Caso A)
  Widget _listaBarriosFiltrable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _barriosFiltrados.isNotEmpty
        ? _barriosFiltrados
        : _barriosCoordenadas;

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 2),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF475569) : AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () {
            setState(() {
              barrioController.text   = items[i];
              _barriosFiltrados       = [];
              _barrioSeleccionado     = true;
            });
            _barrioFocus.unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.place_outlined, size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub),
              const SizedBox(width: 8),
              Expanded(child: Text(items[i],
                  style: GoogleFonts.inter(fontSize: 13,
                      color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain))),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar hurto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Banner de contexto ──
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A5F).withValues(alpha: 0.4)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFFF59E0B),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu reporte es completamente anónimo. La información que compartes '
                      'nos ayuda a identificar zonas de riesgo y mejorar la seguridad en la ciudad.\n'
                      'Cada reporte cuenta y puede ayudar a prevenir que otras personas pasen por lo mismo.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 1. Fecha del incidente
            TextFormField(
              controller: fechaController,
              readOnly: true,
              onTap: _seleccionarFecha,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              decoration: InputDecoration(
                labelText: 'Fecha del incidente *',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // 2. Franja horaria
            _dropdown<String>(
              label: 'Franja horaria *',
              value: franjaHoraria,
              items: _franjasHorarias,
              onChanged: (v) => setState(() => franjaHoraria = v),
            ),
            const SizedBox(height: 15),

            // 3. Dirección con autocomplete
            TextFormField(
              controller: direccionController,
              focusNode: _direccionFocus,
              onChanged: _onDireccionChanged,
              validator: _validarDireccion,
              decoration: InputDecoration(
                labelText: 'Dirección *',
                prefixIcon: const Icon(Icons.location_on),
                helperText: 'Escribe la calle y número, o selecciona en el mapa',
                helperStyle: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_latitud != null && direccionController.text.trim().isNotEmpty)
                      const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                      tooltip: 'Seleccionar en el mapa',
                      onPressed: isLoading ? null : _abrirSelectorMapa,
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            _listaSugerencias(_sugerenciasDireccion, (s) {
              setState(() {
                direccionController.text = s;
                _sugerenciasDireccion    = [];
              });
            }),
            const SizedBox(height: 15),

            // 4. Barrio (Caso A: lista filtrable / Caso B: autocomplete texto)
            TextFormField(
              controller: barrioController,
              focusNode: _barrioFocus,
              onChanged: _onBarrioChanged,
              validator: _validarBarrio,
              decoration: InputDecoration(
                labelText: 'Barrio donde ocurrió *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: _modoListaBarrios
                    ? '📍 Barrios de Comuna $_comunaDetectada'
                    : _sinCobertura
                        ? 'Barrio no detectado, escríbelo manualmente'
                        : 'Se mostrará una lista de barrios automáticamente al ingresar la dirección. También puedes escribirlo.',
                helperStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: _modoListaBarrios ? AppColors.primary : mutedColor,
                ),
                helperMaxLines: 2,
                suffixIcon: _barrioSeleccionado
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF22C55E), size: 20)
                    : null,
              ),
            ),
            if (_modoListaBarrios && !_barrioSeleccionado)
              _listaBarriosFiltrable()
            else
              _listaSugerencias(_sugerenciasBarrio, (s) {
                setState(() {
                  barrioController.text = s;
                  _sugerenciasBarrio    = [];
                  _barrioSeleccionado   = true;
                });
              }),
            const SizedBox(height: 15),

            // 5. Tipo de hurto
            _dropdown<String>(
              label: 'Tipo de hurto *',
              value: tipoHurto,
              items: _tiposHurto,
              display: (e) => e[0].toUpperCase() + e.substring(1),
              onChanged: (v) => setState(() => tipoHurto = v),
            ),
            const SizedBox(height: 15),

            // 6. ¿Eres víctima o testigo? *
            _dropdown<String>(
              label: '¿Eres víctima o testigo? *',
              value: tipoReportante,
              items: _tiposReportante,
              display: (e) => e[0].toUpperCase() + e.substring(1),
              onChanged: (v) => setState(() => tipoReportante = v),
            ),
            const SizedBox(height: 20),

            // ── Separador sección opcional ──
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'INFORMACIÓN ADICIONAL (OPCIONAL)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // 6. Objeto hurtado (opcional)
            DropdownButtonFormField<String>(
              value: objetoHurtado,
              menuMaxHeight: 260,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'Objeto hurtado (opcional)',
                prefixIcon: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary),
              ),
              items: _objetosHurtados
                  .map((e) {
                    final label = e.replaceAll('_', ' ');
                    var display = label[0].toUpperCase() + label.substring(1);
                    if (e == 'tarjetas_documentos') display = 'Tarjetas y/o documentos';
                    return DropdownMenuItem(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(display,
                            style: GoogleFonts.inter(fontSize: 14)),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (v) => setState(() => objetoHurtado = v),
            ),
            const SizedBox(height: 15),

            // 7. Número de agresores (opcional)
            DropdownButtonFormField<String>(
              value: numeroAgresores,
              menuMaxHeight: 260,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'Número de agresores (opcional)',
                prefixIcon:
                    const Icon(Icons.people_outline, color: AppColors.primary),
                helperText: 'Si no lo recuerdas, selecciona "desconocido" sin problema',
                helperStyle: GoogleFonts.inter(fontSize: 12, color: mutedColor),
              ),
              items: _numAgresores
                  .map((e) {
                    final display = e[0].toUpperCase() + e.substring(1);
                    return DropdownMenuItem(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(display, style: GoogleFonts.inter(fontSize: 14)),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (v) => setState(() => numeroAgresores = v),
            ),
            const SizedBox(height: 15),

            // 9. Descripción (opcional)
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

            // ── Botón enviar ──
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
            const SizedBox(height: 8),

            // ── Texto informativo post-envío ──
            Center(
              child: Text(
                'Tu reporte aparecerá en el mapa muy pronto.',
                style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
