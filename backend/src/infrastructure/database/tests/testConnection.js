import supabase from '../dbScript/db.js';

const testConnection = async () => {
 try {

  const { data, error } = await supabase
   .from('reportes')
   .select('*')
   .limit(1);

  if (error) throw error;

  console.log('✅ Conexión exitosa a Supabase:', data);

 } catch (err) {

  console.error('❌ Error:', err.message);

 }

};

testConnection();