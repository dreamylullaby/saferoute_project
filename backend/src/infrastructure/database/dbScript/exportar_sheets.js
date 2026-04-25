// exportar_sheets.js
import { google } from 'googleapis';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const SHEET_ID = process.env.GOOGLE_SHEET_ID;
const KEY_FILE = process.env.GOOGLE_KEY_FILE || 'credenciales-google.json';

async function exportarASheets() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  // Lee la vista que ya tiene todo calculado
  const { data: rows, error } = await supabase
    .from('vw_dashboard_incidentes')
    .select('tipo_hurto, fecha_incidente, anio, mes, nombre_mes, franja_horaria, comuna, barrio, cantidad_reportes, victimas, testigos, nivel_riesgo, latitud_centro, longitud_centro')
    .order('fecha_incidente', { ascending: false });

  if (error) throw new Error(`Error al consultar vista: ${error.message}`);

  const encabezado = [[
    'tipo_hurto', 'fecha_incidente', 'anio', 'mes', 'nombre_mes',
    'franja_horaria', 'comuna', 'barrio', 'cantidad_reportes',
    'victimas', 'testigos', 'nivel_riesgo',
    'latitud_centro', 'longitud_centro'
  ]];

  const filas = rows.map(r => [
    r.tipo_hurto,
    r.fecha_incidente,
    r.anio, r.mes,
    r.nombre_mes?.trim(),
    r.franja_horaria,
    r.comuna,
    r.barrio ?? 'Sin barrio',
    r.cantidad_reportes,
    r.victimas,
    r.testigos,
    r.nivel_riesgo,
    r.latitud_centro,
    r.longitud_centro,
  ]);

  // Limpia y reescribe toda la hoja
  await sheets.spreadsheets.values.clear({
    spreadsheetId: SHEET_ID,
    range: 'Hoja 1',
  });
  await sheets.spreadsheets.values.update({
    spreadsheetId: SHEET_ID,
    range: 'Hoja 1!A1',
    valueInputOption: 'RAW',
    requestBody: { values: [...encabezado, ...filas] },
  });

  console.log(`✅ ${filas.length} incidentes exportados a Google Sheets`);
}

exportarASheets().catch(console.error);
