import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const geojson = JSON.parse(fs.readFileSync('./pasto_secciones.geojson', 'utf8'));

const sectorComuna = {
  '0001': 1,
  '0002': 2,
  '0003': 3,
  '0004': 4,
  '0005': 5,
  '0006': 7,
  '0007': 1,
  '0008': 1,
  '0009': 9,
  '0010': 1,
  '0011': 1,
  '0012': 12,
  '0013': 12,
  '0014': 12,
  '0015': 1,
  '0016': 7,
  '0017': 4,
  '0018': 3,
  '0019': 6,
  '0020': 5,
  '0021': 5,
  '0022': 2,
  '0023': 10,
  '0024': 6,
  '0025': 5,
  '0026': 2,
  '0027': 11,
};

let exitosos = 0;
let fallidos = 0;

for (const feature of geojson.features) {
  const props = feature.properties;
  
  // Solo procesar sectores urbanos (setr_ccdgo = '000')
  if (props.setr_ccdgo !== '000') continue;

  const comuna = sectorComuna[props.setu_ccdgo] ?? null;

  const { error } = await supabase
    .from('secciones_dane')
    .insert({
      secu_ccdgo: props.secu_ccdgo,
      setu_ccdgo: props.setu_ccdgo,
      comuna: comuna,
      geom: feature.geometry
    });

  if (error) {
    console.error(`Error en sección ${props.setu_ccdgo}:`, error.message);
    fallidos++;
  } else {
    console.log(`✓ Sección ${props.setu_ccdgo} → Comuna ${comuna}`);
    exitosos++;
  }
}

console.log(`\nListo: ${exitosos} exitosas, ${fallidos} fallidas`);