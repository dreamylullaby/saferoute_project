import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const geojson = JSON.parse(
  fs.readFileSync('./secciones-pasto-mapa/pasto_rural_sector.geojson', 'utf8')
);

// Mapeo: setr_ccdgo → nombres de corregimientos que contiene
const sectorCorregimientos = {
  '001': ['Buesaquillo'],
  '002': ['Morasurco'],
  '003': ['Catambuco'],
  '004': ['San Fernando'],
  '005': ['La Laguna'],
  '006': ['Gualmatán', 'Obonuco'],
  '007': ['Jongovito', 'Jamondino', 'Mocondino'],
  '008': ['Mapachico', 'Genoy'],
  '009': ['La Caldera'],
  '010': ['El Encano', 'El Socorro'],
  '011': ['Santa Bárbara'],
  '012': ['Cabrera'],
};

// Solo sectores rurales
const rurales = geojson.features.filter(
  f => f.properties.clas_ccdgo === '3'
);

let exitosos = 0;
let fallidos = 0;

for (const feature of rurales) {
  const setr = feature.properties.setr_ccdgo;
  const corregimientos = sectorCorregimientos[setr];

  if (!corregimientos) {
    console.log(`⚠️ Sin mapeo para sector ${setr}, saltando...`);
    continue;
  }

  // Actualizar geom en cada corregimiento de este sector
  for (const nombre of corregimientos) {
    const { error } = await supabase
      .from('corregimientos')
      .update({ geom: feature.geometry })
      .eq('nombre', nombre);

    if (error) {
      console.error(`❌ Error en ${nombre}:`, error.message);
      fallidos++;
    } else {
      console.log(`✓ ${nombre} → sector ${setr}`);
      exitosos++;
    }
  }
}

console.log(`\nListo: ${exitosos} exitosos, ${fallidos} fallidos`);