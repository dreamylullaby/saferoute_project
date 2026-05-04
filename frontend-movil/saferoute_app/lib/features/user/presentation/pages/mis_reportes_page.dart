import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../services/auth_storage.dart';
import '../widgets/app_dropdown.dart';

class MisReportesPage extends StatefulWidget {
  const MisReportesPage({super.key});
  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage> {
  bool _cargando = true;
  List<Map<String, dynamic>> _reportes = [];
  final String _base = '${dotenv.env['API_BASE_URL']}/api/reportes';

  static const _coloresTipo = {
    'atraco': AppColors.hurtoAtraco,
    'raponazo': AppColors.hurtoRaponazo,
    'fleteo': AppColors.hurtoFleteo,
    'cosquilleo': AppColors.hurtoCosquilleo,
  };

  static const _coloresEstado = {
    'activo': Color(0xFF16A34A),
    'oculto': Color(0xFFD97706),
    'eliminado': Color(0xFFDC2626),
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await http.get(Uri.parse('$_base/mis-reportes'), headers: await _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (!mounted) return;
        setState(() { _reportes = List<Map<String, dynamic>>.from(body['data'] ?? []); _cargando = false; });
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error cargando mis reportes: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  String _fmtFecha(String? f) {
    if (f == null) return '—';
    final p = f.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : f;
  }

  void _mostrarMensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: error ? AppColors.hurtoAtraco : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Editar reporte (todos los campos) ──
  void _editarReporte(Map<String, dynamic> r) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _EditarReportePage(
        reporte: r,
        baseUrl: _base,
        onGuardado: () { _cargar(); _mostrarMensaje('Reporte actualizado'); },
        onError: (msg) => _mostrarMensaje(msg, error: true),
      ),
    ));
  }

  // ── Solicitar eliminación ──
  void _solicitarEliminacion(Map<String, dynamic> r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textM = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textS = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final motivoCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        const Icon(Icons.delete_outline, color: AppColors.hurtoAtraco, size: 22),
        const SizedBox(width: 8),
        Text('Solicitar eliminación', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.hurtoAtraco)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tu solicitud será revisada por un administrador.', style: GoogleFonts.inter(fontSize: 14, color: textM)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.hurtoAtraco.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${(r['tipo_hurto'] as String? ?? '')[0].toUpperCase()}${(r['tipo_hurto'] as String? ?? '').substring(1)} · ${_fmtFecha(r['fecha_incidente'] as String?)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textM)),
            Text(r['barrio_ingresado'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: textS)),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Motivo (opcional)', style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(controller: motivoCtrl, maxLines: 2, maxLength: 200, decoration: InputDecoration(hintText: 'Ej: Reporte duplicado', filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: textS))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final body = motivoCtrl.text.trim().isNotEmpty ? {'motivo': motivoCtrl.text.trim()} : {};
              final res = await http.post(Uri.parse('$_base/${r['id']}/solicitar-eliminacion'), headers: await _headers, body: jsonEncode(body));
              if (res.statusCode == 200 || res.statusCode == 201) {
                _mostrarMensaje('Solicitud enviada. Un administrador la revisará.');
              } else {
                final err = jsonDecode(res.body);
                _mostrarMensaje(err['message'] ?? 'Error al solicitar', error: true);
              }
            } catch (e) { _mostrarMensaje('Error de conexión', error: true); }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.hurtoAtraco,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Enviar solicitud'),
        ),
      ],
    ));
  }

  // ── Ver detalle ──
  void _verDetalle(Map<String, dynamic> r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textM = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textS = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: sheetBg, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) {
      return DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false, builder: (_, sc) {
        return ListView(controller: sc, padding: const EdgeInsets.all(20), children: [
          Row(children: [
            Text('Detalle del reporte', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: textM)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 16),
          _detRow('Tipo', '${(r['tipo_hurto'] as String? ?? '')[0].toUpperCase()}${(r['tipo_hurto'] as String? ?? '').substring(1)}', textM, textS),
          _detRow('Estado', r['estado'] ?? '—', textM, textS),
          _detRow('Fecha', _fmtFecha(r['fecha_incidente'] as String?), textM, textS),
          _detRow('Franja', r['franja_horaria'] ?? '—', textM, textS),
          _detRow('Barrio', r['barrio_ingresado'] ?? '—', textM, textS),
          _detRow('Comuna', r['comuna'] != null ? 'Comuna ${r['comuna']}' : '—', textM, textS),
          _detRow('Objeto hurtado', r['objeto_hurtado'] ?? '—', textM, textS),
          _detRow('N° agresores', '${r['numero_agresores'] ?? '—'}', textM, textS),
          if (r['descripcion'] != null) ...[
            const SizedBox(height: 12),
            Text('Descripción', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textM)),
            const SizedBox(height: 4),
            Text(r['descripcion'], style: GoogleFonts.inter(fontSize: 13, color: textS, height: 1.5)),
          ],
        ]);
      });
    });
  }

  Widget _detRow(String label, String value, Color textM, Color textS) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textS))),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: textM), textAlign: TextAlign.right)),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final textMain = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textSub = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final borderColor = isDark ? const Color(0xFF475569) : AppColors.border;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _reportes.isEmpty
              ? _emptyState(textMain, textSub)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reportes.length,
                    itemBuilder: (_, i) => _reporteCard(_reportes[i], cardColor, textMain, textSub, borderColor),
                  ),
                ),
    );
  }

  Widget _emptyState(Color textM, Color textS) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.description_outlined, size: 64, color: AppColors.border),
        const SizedBox(height: 16),
        Text('Aún no has registrado ningún reporte', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textM), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Cuando registres un incidente, aparecerá aquí.', style: GoogleFonts.inter(fontSize: 13, color: textS), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/reportar'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Reportar incidente'),
        ),
      ]),
    ));
  }

  Widget _reporteCard(Map<String, dynamic> r, Color card, Color textM, Color textS, Color border) {
    final tipo = r['tipo_hurto'] as String? ?? '';
    final tipoColor = _coloresTipo[tipo] ?? AppColors.textSub;
    final estado = r['estado'] as String? ?? 'activo';
    final estadoColor = _coloresEstado[estado] ?? const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: tipoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
              child: Text(tipo.isNotEmpty ? '${tipo[0].toUpperCase()}${tipo.substring(1)}' : '', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: tipoColor)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
              child: Text(estado, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: estadoColor)),
            ),
            const Spacer(),
            Text(_fmtFecha(r['fecha_incidente'] as String?), style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w300)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16, color: textS),
              const SizedBox(width: 6),
              Expanded(child: Text('${r['barrio_ingresado'] ?? '—'}${r['comuna'] != null ? ' · Comuna ${r['comuna']}' : ''}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textM))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.access_time, size: 16, color: textS),
              const SizedBox(width: 6),
              Text(r['franja_horaria'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: textS)),
            ]),
            if (r['descripcion'] != null && (r['descripcion'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r['descripcion'], style: GoogleFonts.inter(fontSize: 12, color: textS, fontWeight: FontWeight.w300), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(children: [
              _actionBtn(Icons.visibility_outlined, 'Ver', AppColors.primary, () => _verDetalle(r)),
              if (estado == 'activo') ...[
                const SizedBox(width: 8),
                _actionBtn(Icons.edit_outlined, 'Editar', const Color(0xFFD97706), () => _editarReporte(r)),
                const SizedBox(width: 8),
                _actionBtn(Icons.delete_outline, 'Eliminar', AppColors.hurtoAtraco, () => _solicitarEliminacion(r)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}

/// Página completa de edición de reporte con todos los campos.
class _EditarReportePage extends StatefulWidget {
  const _EditarReportePage({required this.reporte, required this.baseUrl, required this.onGuardado, required this.onError});
  final Map<String, dynamic> reporte;
  final String baseUrl;
  final VoidCallback onGuardado;
  final void Function(String) onError;
  @override
  State<_EditarReportePage> createState() => _EditarReportePageState();
}

class _EditarReportePageState extends State<_EditarReportePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _barrioCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _veredaCtrl;

  String? _fechaISO;
  String? _franjaHoraria;
  String? _tipoHurto;
  String? _tipoReportante;
  String? _objetoHurtado;
  String? _selNumAgresores;
  bool _guardando = false;

  bool get _esRural => widget.reporte['es_rural'] == true;

  static const _franjasHorarias = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  static const _tiposHurto = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];
  static const _tiposReportante = ['victima', 'testigo'];
  static const _objetosHurtados = ['celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos'];
  static const _opcionesAgresores = ['1', '2', '3+', 'desconocido'];

  @override
  void initState() {
    super.initState();
    final r = widget.reporte;
    _fechaISO = r['fecha_incidente'] as String?;
    _fechaCtrl = TextEditingController(text: _fmtFechaEdit(_fechaISO));
    _direccionCtrl = TextEditingController(text: r['direccion'] as String? ?? '');
    _barrioCtrl = TextEditingController(text: r['barrio_ingresado'] as String? ?? '');
    _descCtrl = TextEditingController(text: r['descripcion'] as String? ?? '');
    _veredaCtrl = TextEditingController(text: r['vereda'] as String? ?? '');
    _franjaHoraria = r['franja_horaria'] as String?;
    _tipoHurto = r['tipo_hurto'] as String? ?? 'atraco';
    _tipoReportante = r['tipo_reportante'] as String?;
    _objetoHurtado = r['objeto_hurtado'] as String?;
    _selNumAgresores = r['numero_agresores'] as String?;
  }

  String _fmtFechaEdit(String? f) {
    if (f == null) return '';
    final p = f.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : f;
  }

  Future<void> _seleccionarFecha() async {
    DateTime? initial;
    if (_fechaISO != null) {
      try { initial = DateTime.parse(_fechaISO!); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null) {
      _fechaISO = picked.toIso8601String().split('T')[0];
      _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = <String, dynamic>{
        'tipo_hurto': _tipoHurto,
        'descripcion': _descCtrl.text.trim(),
        'fecha_incidente': _fechaISO,
        'franja_horaria': _franjaHoraria,
        'tipo_reportante': _tipoReportante,
      };
      if (_objetoHurtado != null) body['objeto_hurtado'] = _objetoHurtado;
      if (_selNumAgresores != null) body['numero_agresores'] = _selNumAgresores;

      if (_esRural) {
        body['vereda'] = _veredaCtrl.text.trim();
      } else {
        body['direccion'] = _direccionCtrl.text.trim();
        body['barrio_ingresado'] = _barrioCtrl.text.trim();
      }

      final res = await http.put(
        Uri.parse('${widget.baseUrl}/${widget.reporte['id']}'),
        headers: await _headers,
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        widget.onGuardado();
        Navigator.pop(context);
      } else {
        final err = jsonDecode(res.body);
        widget.onError(err['message'] ?? 'Error al actualizar');
      }
    } catch (_) {
      widget.onError('Error de conexión');
    }
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar reporte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Fecha
            TextFormField(
              controller: _fechaCtrl, readOnly: true, onTap: _seleccionarFecha,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              decoration: InputDecoration(
                labelText: 'Fecha del incidente *', prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // Franja horaria
            AppDropdown<String>(label: 'Franja horaria *', value: _franjaHoraria,
                items: _franjasHorarias, onChanged: (v) => setState(() => _franjaHoraria = v)),
            const SizedBox(height: 15),

            // Campos según zona
            if (!_esRural) ...[
              // Dirección
              TextFormField(
                controller: _direccionCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                decoration: InputDecoration(
                  labelText: 'Dirección *', prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              // Barrio
              TextFormField(
                controller: _barrioCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                decoration: InputDecoration(
                  labelText: 'Barrio *', prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
            ] else ...[
              // Vereda
              TextFormField(
                controller: _veredaCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                decoration: InputDecoration(
                  labelText: 'Vereda *', prefixIcon: const Icon(Icons.terrain),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
            ],

            // Tipo de hurto
            AppDropdown<String>(label: 'Tipo de hurto *', value: _tipoHurto, items: _tiposHurto,
                display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => _tipoHurto = v)),
            const SizedBox(height: 15),

            // Víctima o testigo
            AppDropdown<String>(label: '¿Eres víctima o testigo? *', value: _tipoReportante,
                items: _tiposReportante, display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => _tipoReportante = v)),
            const SizedBox(height: 20),

            // Separador
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text('INFORMACIÓN ADICIONAL (OPCIONAL)',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: mutedColor, letterSpacing: 0.5))),

            // Objeto hurtado
            DropdownButtonFormField<String>(
              value: _objetoHurtado, menuMaxHeight: 260, borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              decoration: InputDecoration(labelText: 'Objeto hurtado (opcional)',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary)),
              items: [
                const DropdownMenuItem<String>(value: null, child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Sin especificar'))),
                ..._objetosHurtados.map((e) {
                  final label = e.replaceAll('_', ' ');
                  var display = label[0].toUpperCase() + label.substring(1);
                  if (e == 'tarjetas_documentos') display = 'Tarjetas y/o documentos';
                  return DropdownMenuItem(value: e, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(display, style: GoogleFonts.inter(fontSize: 14))));
                }),
              ],
              onChanged: (v) => setState(() => _objetoHurtado = v),
            ),
            const SizedBox(height: 15),

            // Agresores
            DropdownButtonFormField<String>(
              value: _selNumAgresores, menuMaxHeight: 260, borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              decoration: InputDecoration(labelText: 'Número de agresores (opcional)',
                  prefixIcon: const Icon(Icons.people_outline, color: AppColors.primary)),
              items: [
                const DropdownMenuItem<String>(value: null, child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Sin especificar'))),
                ..._opcionesAgresores.map((e) {
                  final display = e[0].toUpperCase() + e.substring(1);
                  return DropdownMenuItem(value: e, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(display, style: GoogleFonts.inter(fontSize: 14))));
                }),
              ],
              onChanged: (v) => setState(() => _selNumAgresores = v),
            ),
            const SizedBox(height: 15),

            // Descripción
            TextFormField(controller: _descCtrl, maxLength: 300, maxLines: 4,
              decoration: InputDecoration(labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 25),

            // Botón guardar
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _guardando ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar cambios'),
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ]),
        ),
      ),
    );
  }
}
