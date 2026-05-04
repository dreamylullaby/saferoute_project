import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../../../../services/auth_storage.dart';
import '../../data/datasources/geo_service.dart';
import '../../data/datasources/autocomplete_service.dart';
import '../widgets/report_info_banner.dart';
import '../widgets/suggestion_list.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/map_picker_sheet.dart';

/// Pantalla selector Urbano / Rural que abre el formulario correspondiente.
class ReportIncidentePage extends StatelessWidget {
  const ReportIncidentePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textM = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textS = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    const ruralColor = Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar hurto')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_location_alt_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 20),
              Text('¿Dónde ocurrió el incidente?',
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: textM),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Selecciona el tipo de zona para adaptar el formulario.',
                style: GoogleFonts.inter(fontSize: 14, color: textS),
                textAlign: TextAlign.center),
              const SizedBox(height: 36),
              _ZonaCard(
                icon: Icons.location_city,
                label: 'Zona Urbana',
                subtitle: 'Barrios y comunas de la ciudad',
                color: AppColors.primary,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ReportFormPage(esRural: false))),
              ),
              const SizedBox(height: 16),
              _ZonaCard(
                icon: Icons.park_outlined,
                label: 'Zona Rural',
                subtitle: 'Veredas y corregimientos',
                color: ruralColor,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ReportFormPage(esRural: true))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonaCard extends StatelessWidget {
  const _ZonaCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
            ])),
            Icon(Icons.chevron_right_rounded, color: color),
          ]),
        ),
      ),
    );
  }
}


/// Formulario de registro de incidente, adaptado según zona urbana o rural.
class _ReportFormPage extends StatefulWidget {
  const _ReportFormPage({required this.esRural});
  final bool esRural;
  @override
  State<_ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<_ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final fechaController = TextEditingController();
  final direccionController = TextEditingController();
  final barrioController = TextEditingController();
  final descripcionController = TextEditingController();
  final veredaController = TextEditingController();
  final _barrioFocus = FocusNode();
  final _direccionFocus = FocusNode();
  final _filtroBusquedaController = TextEditingController();

  late final GeoService _geoService;
  late final AutocompleteService _autocompleteService;

  bool isLoading = false;
  double? _latitud;
  double? _longitud;
  String? _fechaISO;

  // Barrio state (urbano)
  List<String> _sugerenciasBarrio = [];
  List<String> _barriosCoordenadas = [];
  List<String> _barriosFiltrados = [];
  int? _comunaDetectada;
  bool _sinCobertura = false;
  bool _barrioSeleccionado = false;
  Timer? _debounceBarrio;

  // Dirección state (urbano)
  List<String> _sugerenciasDireccion = [];
  Timer? _debounceDireccion;

  // Rural state
  int? _corregimientoSeleccionado;
  List<Map<String, dynamic>> _corregimientos = [];
  bool _cargandoCorregimientos = false;

  // Selección de campos comunes
  String? tipoReportante;
  String? franjaHoraria;
  String? tipoHurto;
  String? objetoHurtado;
  String? numeroAgresores;

  static const _tiposReportante = ['victima', 'testigo'];
  static const _franjasHorarias = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  static const _tiposHurto = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];
  static const _objetosHurtados = ['celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos'];
  static const _numAgresores = ['1', '2', '3+', 'desconocido'];

  bool get _esRural => widget.esRural;
  bool get _modoListaBarrios => _barriosCoordenadas.isNotEmpty && !_sinCobertura;

  @override
  void initState() {
    super.initState();
    _geoService = GeoService(dotenv.env['MAPBOX_TOKEN'] ?? '');
    _autocompleteService = AutocompleteService(dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000');

    if (_esRural) {
      _cargarCorregimientos();
    }

    _direccionFocus.addListener(() {
      if (!_direccionFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _sugerenciasDireccion = []);
        });
        final texto = direccionController.text.trim();
        if (texto.length >= 5 && _latitud == null) {
          _geocodificarDireccionManual(texto);
        }
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

  // ── Corregimientos (rural) ─────────────────────────────────────────────────

  Future<void> _cargarCorregimientos() async {
    setState(() => _cargandoCorregimientos = true);
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final token = await AuthStorage.getToken();
      final res = await http.get(Uri.parse('$base/api/reportes/corregimientos'),
        headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) setState(() {
          _corregimientos = List<Map<String, dynamic>>.from(body['data'] ?? []);
          _cargandoCorregimientos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoCorregimientos = false);
    }
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

  // ── Dirección (urbano) ─────────────────────────────────────────────────────

  Future<void> _geocodificarDireccionManual(String texto) async {
    final coords = await _geoService.geocodificarDireccion(texto);
    if (coords != null && mounted) {
      setState(() { _latitud = coords.lat; _longitud = coords.lng; });
      await _buscarBarriosPorCoordenadas(coords.lat, coords.lng);
    }
  }

  void _onDireccionChanged(String valor) {
    _debounceDireccion?.cancel();
    if (valor.trim().length < 4) {
      setState(() => _sugerenciasDireccion = []);
      return;
    }
    _debounceDireccion = Timer(const Duration(milliseconds: 400), () async {
      final sugs = await _geoService.buscarDirecciones(valor.trim());
      if (mounted) setState(() => _sugerenciasDireccion = sugs);
    });
  }

  Future<void> _abrirSelectorMapa() async {
    final punto = await MapPickerSheet.show(context);
    if (punto == null || !mounted) return;
    setState(() => isLoading = true);
    final dir = await _geoService.geocodificarInverso(punto.latitude, punto.longitude);
    if (!mounted) return;
    setState(() {
      _latitud = punto.latitude;
      _longitud = punto.longitude;
      if (dir.isNotEmpty) { direccionController.text = dir; _sugerenciasDireccion = []; }
      isLoading = false;
    });
    if (!_esRural) await _buscarBarriosPorCoordenadas(punto.latitude, punto.longitude);
  }

  // ── Barrio (urbano) ────────────────────────────────────────────────────────

  Future<void> _buscarBarriosPorCoordenadas(double lat, double lng) async {
    final result = await _autocompleteService.buscarBarriosPorCoordenadas(lat, lng);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _comunaDetectada = result.comuna;
        _barriosCoordenadas = result.barrios;
        _barriosFiltrados = [];
        _sinCobertura = false;
        barrioController.clear();
        _barrioSeleccionado = false;
        _filtroBusquedaController.clear();
      });
    } else {
      setState(() {
        _comunaDetectada = null;
        _barriosCoordenadas = [];
        _barriosFiltrados = [];
        _sinCobertura = true;
        barrioController.clear();
        _barrioSeleccionado = false;
      });
    }
  }

  void _onBarrioChanged(String valor) {
    if (_modoListaBarrios) {
      final lower = valor.trim().toLowerCase();
      setState(() {
        _barrioSeleccionado = false;
        _barriosFiltrados = lower.isEmpty ? [] :
            _barriosCoordenadas.where((b) => b.toLowerCase().contains(lower)).take(8).toList();
      });
      return;
    }
    _debounceBarrio?.cancel();
    setState(() => _barrioSeleccionado = false);
    if (valor.trim().length < 2) {
      setState(() => _sugerenciasBarrio = []);
      return;
    }
    _debounceBarrio = Timer(const Duration(milliseconds: 350), () async {
      final lista = await _autocompleteService.buscarBarriosPorTexto(valor.trim());
      if (mounted) setState(() => _sugerenciasBarrio = lista);
    });
  }

  // ── Enviar reporte ─────────────────────────────────────────────────────────

  void enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    // En urbano, coordenadas son obligatorias
    if (!_esRural && (_latitud == null || _longitud == null)) {
      mostrarError(context, 'Debes seleccionar la ubicación del incidente en el mapa.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      final userId = await AuthStorage.getUserId();

      final body = <String, dynamic>{
        'usuario_id': userId,
        'tipo_reportante': tipoReportante,
        'fecha_incidente': _fechaISO,
        'franja_horaria': franjaHoraria,
        'tipo_hurto': tipoHurto,
        'descripcion': descripcionController.text.trim(),
        'objeto_hurtado': objetoHurtado,
        'numero_agresores': numeroAgresores,
      };

      if (_esRural) {
        body['es_rural'] = true;
        body['vereda'] = veredaController.text.trim();
        body['corregimiento_id'] = _corregimientoSeleccionado;
        if (_latitud != null && _longitud != null) {
          body['latitud'] = _latitud;
          body['longitud'] = _longitud;
        }
      } else {
        body['latitud'] = _latitud;
        body['longitud'] = _longitud;
        body['direccion'] = direccionController.text.trim();
        body['barrio_ingresado'] = barrioController.text.trim();
      }

      final res = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/reportes'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        mostrarExito(context, 'Tu reporte fue enviado exitosamente.',
            alCerrar: () { Navigator.pop(context); Navigator.pop(context); });
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
    if (s.length < 5) return 'La dirección debe tener al menos 5 caracteres';
    if (!RegExp(r'\d').hasMatch(s)) return 'Incluye un número en la dirección (ej: Cra 15 #22-10)';
    if (RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s#\-\.]').hasMatch(s)) return 'Solo letras, números, #, - y puntos';
    return null;
  }

  String? _validarBarrio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    if (s.length < 3) return 'Mínimo 3 caracteres';
    if (RegExp(r'\d').hasMatch(s)) return 'El barrio no debe contener números';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(s)) return 'Solo letras y espacios';
    return null;
  }

  String? _validarVereda(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  // ── Lista filtrable barrios (urbano) ────────────────────────────────────────

  Widget _listaBarriosFiltrable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _barriosFiltrados.isNotEmpty ? _barriosFiltrados : _barriosCoordenadas;
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
        shrinkWrap: true, padding: EdgeInsets.zero, itemCount: items.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () {
            setState(() { barrioController.text = items[i]; _barriosFiltrados = []; _barrioSeleccionado = true; });
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
    const ruralColor = Color(0xFF16A34A);
    final accentColor = _esRural ? ruralColor : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esRural ? 'Hurto en zona rural' : 'Hurto en zona urbana'),
        backgroundColor: _esRural ? const Color(0xFF166534) : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ReportInfoBanner(),

            // Indicador de zona
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_esRural ? Icons.park_outlined : Icons.location_city, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(_esRural ? 'Zona Rural' : 'Zona Urbana',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor)),
              ]),
            ),

            // 1. Fecha
            TextFormField(
              controller: fechaController, readOnly: true, onTap: _seleccionarFecha,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              decoration: InputDecoration(
                labelText: 'Fecha del incidente *', prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // 2. Franja horaria
            AppDropdown<String>(label: 'Franja horaria *', value: franjaHoraria,
                items: _franjasHorarias, onChanged: (v) => setState(() => franjaHoraria = v)),
            const SizedBox(height: 15),

            // ── Campos según zona ──
            if (!_esRural) ..._buildCamposUrbanos(mutedColor)
            else ..._buildCamposRurales(mutedColor, accentColor),

            const SizedBox(height: 15),

            // Tipo de hurto
            AppDropdown<String>(label: 'Tipo de hurto *', value: tipoHurto, items: _tiposHurto,
                display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => tipoHurto = v)),
            const SizedBox(height: 15),

            // Víctima o testigo
            AppDropdown<String>(label: '¿Eres víctima o testigo? *', value: tipoReportante,
                items: _tiposReportante, display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => tipoReportante = v)),
            const SizedBox(height: 20),

            // Separador
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text('INFORMACIÓN ADICIONAL (OPCIONAL)',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: mutedColor, letterSpacing: 0.5))),

            // Objeto hurtado
            DropdownButtonFormField<String>(
              value: objetoHurtado, menuMaxHeight: 260, borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              decoration: InputDecoration(labelText: 'Objeto hurtado (opcional)',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary)),
              items: _objetosHurtados.map((e) {
                final label = e.replaceAll('_', ' ');
                var display = label[0].toUpperCase() + label.substring(1);
                if (e == 'tarjetas_documentos') display = 'Tarjetas y/o documentos';
                return DropdownMenuItem(value: e, child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(display, style: GoogleFonts.inter(fontSize: 14))));
              }).toList(),
              onChanged: (v) => setState(() => objetoHurtado = v),
            ),
            const SizedBox(height: 15),

            // Agresores
            DropdownButtonFormField<String>(
              value: numeroAgresores, menuMaxHeight: 260, borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              decoration: InputDecoration(labelText: 'Número de agresores (opcional)',
                  prefixIcon: const Icon(Icons.people_outline, color: AppColors.primary),
                  helperText: 'Si no lo recuerdas, selecciona "desconocido" sin problema',
                  helperStyle: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
              items: _numAgresores.map((e) {
                final display = e[0].toUpperCase() + e.substring(1);
                return DropdownMenuItem(value: e, child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(display, style: GoogleFonts.inter(fontSize: 14))));
              }).toList(),
              onChanged: (v) => setState(() => numeroAgresores = v),
            ),
            const SizedBox(height: 15),

            // Descripción
            TextFormField(controller: descripcionController, maxLength: 300, maxLines: 4,
              decoration: InputDecoration(labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 25),

            // Botón enviar
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: isLoading ? null : enviarReporte,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar reporte'),
            )),
            const SizedBox(height: 8),
            Center(child: Text('Tu reporte aparecerá en el mapa muy pronto.',
                style: GoogleFonts.inter(fontSize: 12, color: mutedColor))),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ]),
        ),
      ),
    );
  }

  // ── Campos urbanos ─────────────────────────────────────────────────────────

  List<Widget> _buildCamposUrbanos(Color mutedColor) {
    return [
      // Dirección
      TextFormField(
        controller: direccionController, focusNode: _direccionFocus,
        onChanged: _onDireccionChanged, validator: _validarDireccion,
        decoration: InputDecoration(
          labelText: 'Dirección *', prefixIcon: const Icon(Icons.location_on),
          helperText: 'Escribe la calle y número, o selecciona en el mapa',
          helperStyle: GoogleFonts.inter(fontSize: 12, color: mutedColor),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_latitud != null && direccionController.text.trim().isNotEmpty)
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
            IconButton(icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                tooltip: 'Seleccionar en el mapa',
                onPressed: isLoading ? null : _abrirSelectorMapa),
          ]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      SuggestionList(items: _sugerenciasDireccion, onSelect: (s) async {
        setState(() { direccionController.text = s; _sugerenciasDireccion = []; });
        final coords = await _geoService.geocodificarDireccion(s);
        if (coords != null && mounted) {
          setState(() { _latitud = coords.lat; _longitud = coords.lng; });
          await _buscarBarriosPorCoordenadas(coords.lat, coords.lng);
        }
      }),
      const SizedBox(height: 15),

      // Barrio
      TextFormField(
        controller: barrioController, focusNode: _barrioFocus,
        onChanged: _onBarrioChanged, validator: _validarBarrio,
        enabled: direccionController.text.trim().isNotEmpty,
        decoration: InputDecoration(
          labelText: 'Barrio donde ocurrió *', prefixIcon: const Icon(Icons.map),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          helperText: direccionController.text.trim().isEmpty
              ? 'Primero ingresa la dirección del incidente'
              : _modoListaBarrios ? '📍 Barrios de Comuna $_comunaDetectada'
              : _sinCobertura ? 'Barrio no detectado, escríbelo manualmente'
              : 'Se mostrará una lista de barrios automáticamente al ingresar la dirección. También puedes escribirlo.',
          helperStyle: GoogleFonts.inter(fontSize: 12,
              color: _modoListaBarrios ? AppColors.primary : mutedColor),
          helperMaxLines: 2,
          suffixIcon: _barrioSeleccionado
              ? const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20) : null,
        ),
      ),
      if (_modoListaBarrios && !_barrioSeleccionado) _listaBarriosFiltrable()
      else SuggestionList(items: _sugerenciasBarrio, onSelect: (s) {
        setState(() { barrioController.text = s; _sugerenciasBarrio = []; _barrioSeleccionado = true; });
      }),
    ];
  }

  // ── Campos rurales ─────────────────────────────────────────────────────────

  List<Widget> _buildCamposRurales(Color mutedColor, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      // Corregimiento
      _cargandoCorregimientos
        ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : DropdownButtonFormField<int>(
            value: _corregimientoSeleccionado,
            menuMaxHeight: 300,
            borderRadius: BorderRadius.circular(14),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
            decoration: InputDecoration(
              labelText: 'Corregimiento *',
              prefixIcon: Icon(Icons.park_outlined, color: accentColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null ? 'Campo obligatorio' : null,
            items: _corregimientos.map((c) => DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(c['nombre'] ?? '', style: GoogleFonts.inter(fontSize: 14)),
              ),
            )).toList(),
            onChanged: (v) => setState(() => _corregimientoSeleccionado = v),
          ),
      const SizedBox(height: 15),

      // Vereda
      TextFormField(
        controller: veredaController,
        validator: _validarVereda,
        decoration: InputDecoration(
          labelText: 'Nombre de la vereda *',
          prefixIcon: Icon(Icons.terrain, color: accentColor),
          helperText: 'Escribe el nombre de la vereda donde ocurrió el incidente',
          helperStyle: GoogleFonts.inter(fontSize: 12, color: mutedColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 15),

      // Ubicación en mapa (opcional en rural)
      TextFormField(
        controller: direccionController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Ubicación en mapa (opcional)',
          prefixIcon: const Icon(Icons.location_on),
          helperText: _latitud != null
              ? 'Ubicación seleccionada ✓'
              : 'Puedes marcar la ubicación aproximada en el mapa',
          helperStyle: GoogleFonts.inter(fontSize: 12,
              color: _latitud != null ? const Color(0xFF22C55E) : mutedColor),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_latitud != null)
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
            IconButton(icon: Icon(Icons.map_outlined, color: accentColor),
                tooltip: 'Seleccionar en el mapa',
                onPressed: isLoading ? null : _abrirSelectorMapa),
          ]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ];
  }
}
