/**
 * Cliente de Supabase para acceso a la base de datos.
 * Lee las credenciales desde las variables de entorno definidas en .env
 * @module db
 */
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

export default supabase;
