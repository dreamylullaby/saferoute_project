import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/auth_storage.dart';

class ReportIncidentePage extends StatefulWidget {
  const ReportIncidentePage({super.key});

  @override
  State<ReportIncidentePage> createState() => _ReportIncidentePageState();
}

class _ReportIncidentePageState extends State<ReportIncidentePage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Controladores de texto
  final fechaController        = TextEditingController();
  final latitudController      = TextEditingController();
  final longitudController     = TextEditingController();
  final direccionController    = TextEditingController();
  final barrioController       = TextEditingController();
  final descripcionController  = TextEditingController();

  // Valores de dropdowns
  String? tipoReportante;
  String? franjaHoraria;
  String? tipoHurto;
  String? objetoHurtado;
  String? numeroAgresores;

  // Opciones
  final _tiposReportante  = ['victima', 'testigo'];
  final _franjasHorarias  = ['00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59'];
  final _tiposHurto       = ['atraco', 'raponazo', 'cosquilleo', 'fleteo'];
  final _objetosHurtados  = ['celular', 'dinero', 'tarjetas_documentos', 'articulos_personales', 'dispositivos_electronicos'];
  final _numAgresores     = ['1', '2', '3+', 'desconocido'];

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

  void enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await AuthStorage.getToken();
      final userId = await AuthStorage.getUserId();

      final response = await http.post(
        Uri.parse("http://localhost:3000/api/reportes"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "usuario_id":       userId,
          "tipo_reportante":  tipoReportante,
          "fecha_incidente":  fechaController.text,
          "franja_horaria":   franjaHoraria,
          "latitud":          double.parse(latitudController.text),
          "longitud":         double.parse(longitudController.text),
          "direccion":        direccionController.text.trim(),
          "barrio_ingresado": barrioController.text.trim(),
          "tipo_hurto":       tipoHurto,
          "descripcion":      descripcionController.text.trim(),
          "objeto_hurtado":   objetoHurtado,
          "numero_agresores": numeroAgresores,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reporte enviado exitosamente")),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Error al enviar reporte")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String Function(T)? display,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) => DropdownMenuItem(
        value: e,
        child: Text(display != null ? display(e) : e.toString()),
      )).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Campo obligatorio" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar hurto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // Tipo reportante
              _dropdown<String>(
                label: "¿Eres víctima o testigo?",
                value: tipoReportante,
                items: _tiposReportante,
                display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => tipoReportante = v),
              ),

              const SizedBox(height: 15),

              // Fecha del incidente
              TextFormField(
                controller: fechaController,
                readOnly: true,
                onTap: _seleccionarFecha,
                validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                decoration: InputDecoration(
                  labelText: "Fecha del incidente",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              // Franja horaria
              _dropdown<String>(
                label: "Franja horaria",
                value: franjaHoraria,
                items: _franjasHorarias,
                onChanged: (v) => setState(() => franjaHoraria = v),
              ),

              const SizedBox(height: 15),

              // Latitud y longitud (se llenan automáticamente desde el mapa)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latitudController,
                      readOnly: true,
                      validator: (v) => (v == null || v.isEmpty) ? "Selecciona ubicación en el mapa" : null,
                      decoration: InputDecoration(
                        labelText: "Latitud",
                        prefixIcon: const Icon(Icons.gps_fixed),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: longitudController,
                      readOnly: true,
                      validator: (v) => (v == null || v.isEmpty) ? "Selecciona ubicación en el mapa" : null,
                      decoration: InputDecoration(
                        labelText: "Longitud",
                        prefixIcon: const Icon(Icons.gps_fixed),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Dirección
              TextFormField(
                controller: direccionController,
                decoration: InputDecoration(
                  labelText: "Dirección (opcional)",
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              // Barrio
              TextFormField(
                controller: barrioController,
                validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                decoration: InputDecoration(
                  labelText: "Barrio donde ocurrió",
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 15),

              // Tipo de hurto
              _dropdown<String>(
                label: "Tipo de hurto",
                value: tipoHurto,
                items: _tiposHurto,
                display: (e) => e[0].toUpperCase() + e.substring(1),
                onChanged: (v) => setState(() => tipoHurto = v),
              ),

              const SizedBox(height: 15),

              // Objeto hurtado
              DropdownButtonFormField<String>(
                value: objetoHurtado,
                decoration: InputDecoration(
                  labelText: "Objeto hurtado (opcional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _objetosHurtados.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.replaceAll('_', ' ')),
                )).toList(),
                onChanged: (v) => setState(() => objetoHurtado = v),
              ),

              const SizedBox(height: 15),

              // Número de agresores
              DropdownButtonFormField<String>(
                value: numeroAgresores,
                decoration: InputDecoration(
                  labelText: "Número de agresores (opcional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _numAgresores.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                )).toList(),
                onChanged: (v) => setState(() => numeroAgresores = v),
              ),

              const SizedBox(height: 15),

              // Descripción
              TextFormField(
                controller: descripcionController,
                maxLength: 300,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Descripción (opcional)",
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enviar reporte"),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
