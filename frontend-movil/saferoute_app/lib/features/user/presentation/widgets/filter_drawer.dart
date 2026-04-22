import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import 'filter_chip_group.dart';
import 'filter_date_field.dart';

/// Drawer de filtros del mapa interactivo.
class FilterDrawer extends StatefulWidget {
  const FilterDrawer({
    super.key,
    required this.comunasSeleccionadas,
    required this.franjasSeleccionadas,
    required this.tiposSeleccionados,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.conteoFiltros,
    required this.hayFiltros,
    required this.onAplicar,
    required this.onRestablecer,
    required this.onCerrarSesion,
    this.onPerfil,
    this.onMisReportes,
    this.onFechaDesdeChanged,
    this.onFechaHastaChanged,
  });

  final Set<int> comunasSeleccionadas;
  final Set<String> franjasSeleccionadas;
  final Set<String> tiposSeleccionados;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int conteoFiltros;
  final bool hayFiltros;
  final VoidCallback onAplicar;
  final VoidCallback onRestablecer;
  final VoidCallback onCerrarSesion;
  final VoidCallback? onPerfil;
  final VoidCallback? onMisReportes;
  final void Function(DateTime)? onFechaDesdeChanged;
  final void Function(DateTime)? onFechaHastaChanged;

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late DateTime? _localDesde;
  late DateTime? _localHasta;

  static const _franjas = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  static const _tipos = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];

  static IconData _iconoTipo(String tipo) => switch (tipo) {
    'atraco' => Icons.warning_rounded,
    'raponazo' => Icons.directions_run,
    'fleteo' => Icons.motorcycle,
    'cosquilleo' => Icons.back_hand_outlined,
    _ => Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    _localDesde = widget.fechaDesde;
    _localHasta = widget.fechaHasta;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionText = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Drawer(
      width: 300,
      child: Column(
        children: [
          // Cabecera
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 12, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text('Filtros', style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (widget.hayFiltros) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${widget.conteoFiltros}', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenido scrollable
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Comuna', Icons.map_outlined, sectionText),
                    const SizedBox(height: 8),
                    FilterChipGroup<int>(
                      items: List.generate(12, (i) => i + 1),
                      selected: widget.comunasSeleccionadas,
                      onToggle: (n) => setState(() => widget.comunasSeleccionadas.contains(n)
                          ? widget.comunasSeleccionadas.remove(n)
                          : widget.comunasSeleccionadas.add(n)),
                      labelBuilder: (n) => '$n',
                      useGrid: true,
                      gridColumns: 4,
                    ),
                    const SizedBox(height: 14),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 14),
                    _sectionTitle('Rango horario', Icons.access_time_rounded, sectionText),
                    const SizedBox(height: 8),
                    FilterChipGroup<String>(
                      items: _franjas,
                      selected: widget.franjasSeleccionadas,
                      onToggle: (f) => setState(() => widget.franjasSeleccionadas.contains(f)
                          ? widget.franjasSeleccionadas.remove(f)
                          : widget.franjasSeleccionadas.add(f)),
                      labelBuilder: (f) => f,
                      iconBuilder: (_) => Icons.schedule_rounded,
                      useGrid: true,
                      gridColumns: 2,
                      gridAspectRatio: 3.5,
                    ),
                    const SizedBox(height: 14),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 14),
                    _sectionTitle('Tipo de hurto', Icons.local_police_rounded, sectionText),
                    const SizedBox(height: 8),
                    FilterChipGroup<String>(
                      items: _tipos,
                      selected: widget.tiposSeleccionados,
                      onToggle: (t) => setState(() => widget.tiposSeleccionados.contains(t)
                          ? widget.tiposSeleccionados.remove(t)
                          : widget.tiposSeleccionados.add(t)),
                      labelBuilder: (t) => t[0].toUpperCase() + t.substring(1),
                      iconBuilder: (t) => _iconoTipo(t),
                      useGrid: true,
                      gridColumns: 2,
                      gridAspectRatio: 3.5,
                    ),
                    const SizedBox(height: 14),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 14),
                    _sectionTitle('Fecha del incidente', Icons.calendar_today_rounded, sectionText),
                    const SizedBox(height: 8),
                    FilterDateField(
                      label: 'Desde',
                      value: _localDesde,
                      onPicked: (d) {
                        setState(() => _localDesde = d);
                        widget.onFechaDesdeChanged?.call(d);
                      },
                    ),
                    const SizedBox(height: 12),
                    FilterDateField(
                      label: 'Hasta',
                      value: _localHasta,
                      onPicked: (d) {
                        setState(() => _localHasta = d);
                        widget.onFechaHastaChanged?.call(d);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                // Fade inferior
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(0),
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botones fijos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAplicar();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Aplicar filtros',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _localDesde = null;
                        _localHasta = null;
                      });
                      widget.onRestablecer();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Restablecer filtros',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub)),
                  ),
                ),
              ],
            ),
          ),

          // Navegación
          Divider(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            height: 1, thickness: 0.5,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            child: Column(
              children: [
                _navItem(icon: Icons.person_outline, label: 'Mi perfil',
                    enabled: true, isDark: isDark, onTap: widget.onPerfil),
                _navItem(icon: Icons.bar_chart_rounded, label: 'Estadísticas',
                    enabled: false, isDark: isDark),
                _navItem(icon: Icons.description_outlined, label: 'Mis reportes',
                    enabled: widget.onMisReportes != null, isDark: isDark, onTap: widget.onMisReportes),
                const SizedBox(height: 4),
                _navItem(icon: Icons.logout_rounded, label: 'Cerrar sesión',
                    enabled: true, isDark: isDark, isDestructive: true, onTap: widget.onCerrarSesion),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, color: color)),
    ]);
  }

  Widget _navItem({
    required IconData icon, required String label, required bool isDark,
    bool enabled = true, bool isDestructive = false, VoidCallback? onTap,
  }) {
    final activeColor = isDestructive
        ? AppColors.error : (isDark ? const Color(0xFFE2E8F0) : AppColors.textMain);
    final disabledColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final color = enabled ? activeColor : disabledColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: color))),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Pronto', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: disabledColor)),
              ),
          ]),
        ),
      ),
    );
  }
}
