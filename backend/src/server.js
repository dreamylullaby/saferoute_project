/* Importa la app configurada y levanta el servidor en el puerto definido.
 */

import app from "./app.js";

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));