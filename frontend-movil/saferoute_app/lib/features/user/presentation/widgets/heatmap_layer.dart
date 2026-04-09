import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Punto de datos para el heatmap con coordenadas e intensidad.
class HeatmapPoint {
  final LatLng position;
  final double intensity;
  const HeatmapPoint(this.position, [this.intensity = 1.0]);
}

/// Capa de heatmap real con gradiente de densidad para flutter_map.
/// Agrupa reportes cercanos y pinta manchas con blur gaussiano,
/// produciendo transiciones suaves entre zonas de diferente densidad.
class HeatmapLayer extends StatelessWidget {
  final List<HeatmapPoint> points;

  /// Radio de influencia de cada punto en píxeles de pantalla.
  final double radius;

  /// Opacidad máxima del heatmap (0.0 - 1.0).
  final double maxOpacity;

  /// Blur adicional para suavizar transiciones.
  final double blur;

  const HeatmapLayer({
    super.key,
    required this.points,
    this.radius = 30,
    this.maxOpacity = 0.6,
    this.blur = 15,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return CustomPaint(
      size: Size(camera.size.width, camera.size.height),
      painter: _HeatmapPainter(
        points: points,
        camera: camera,
        radius: radius,
        maxOpacity: maxOpacity,
        blur: blur,
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<HeatmapPoint> points;
  final MapCamera camera;
  final double radius;
  final double maxOpacity;
  final double blur;

  _HeatmapPainter({
    required this.points,
    required this.camera,
    required this.radius,
    required this.maxOpacity,
    required this.blur,
  });

  /// Gradiente de colores del heatmap: verde → amarillo → naranja → rosa oscuro.
  static const _gradientColors = [
    Color(0xFF22C55E), // zona segura
    Color(0xFFFACC15), // bajo riesgo
    Color(0xFFF97316), // riesgo medio
    Color(0xFFBE185D), // alto riesgo
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Convertir coordenadas geográficas a píxeles de pantalla
    final screenPoints = <Offset>[];
    final intensities = <double>[];
    for (final p in points) {
      final px = camera.latLngToScreenOffset(p.position);
      // Solo pintar puntos visibles (con margen del radio)
      if (px.dx > -radius && px.dx < size.width + radius &&
          px.dy > -radius && px.dy < size.height + radius) {
        screenPoints.add(px);
        intensities.add(p.intensity);
      }
    }
    if (screenPoints.isEmpty) return;

    // Calcular la intensidad máxima para normalizar
    double maxIntensity = 0;
    // Usamos una grilla para calcular densidad acumulada
    // Cada punto contribuye con su intensidad al área circundante
    // Pintamos cada punto como un gradiente radial
    for (final intensity in intensities) {
      if (intensity > maxIntensity) maxIntensity = intensity;
    }
    if (maxIntensity == 0) maxIntensity = 1;

    // Guardar estado y aplicar blur al canvas completo
    canvas.saveLayer(Offset.zero & size, Paint());

    final effectiveRadius = radius + blur;

    for (int i = 0; i < screenPoints.length; i++) {
      final center = screenPoints[i];
      final normalizedIntensity = intensities[i] / maxIntensity;

      // Opacidad equilibrada: visible sin tapar el mapa (~65-75%).
      final centerOpacity = (maxOpacity * normalizedIntensity)
          .clamp(0.15, 0.75);
      final midOpacity = (centerOpacity * 0.55).clamp(0.08, 0.40);

      final gradient = ui.Gradient.radial(
        center,
        effectiveRadius,
        [
          _colorForIntensity(normalizedIntensity)
              .withOpacity(centerOpacity),
          _colorForIntensity(normalizedIntensity)
              .withOpacity(midOpacity),
          _colorForIntensity(normalizedIntensity).withOpacity(0),
        ],
        [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(center, effectiveRadius, paint);
    }

    canvas.restore();
  }

  /// Interpola el color según la intensidad normalizada (0.0 - 1.0).
  Color _colorForIntensity(double t) {
    t = t.clamp(0.0, 1.0);
    final colors = _gradientColors;
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;

    final segment = t * (colors.length - 1);
    final index = segment.floor();
    final frac = segment - index;

    if (index >= colors.length - 1) return colors.last;
    return Color.lerp(colors[index], colors[index + 1], frac)!;
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.radius != radius ||
        oldDelegate.maxOpacity != maxOpacity ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.center != camera.center;
  }
}
