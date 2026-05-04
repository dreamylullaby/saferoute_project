# Mejoras extra posibles

Documento temporal para discutir con el asesor y el equipo antes de implementar.

---

## 1. Hard delete de reportes

Actualmente al "eliminar" un reporte solo se hace soft delete (estado = eliminado). El reporte sigue en la BD.

Propuesta: agregar un botón "Eliminar permanentemente" que solo aparezca cuando el reporte ya tiene estado "eliminado". Flujo:
- Admin elimina → soft delete (estado = eliminado)
- Admin filtra por "Eliminado", revisa, confirma → hard delete (se borra de la BD)
- Modal de confirmación: "Esta acción es irreversible"
- Requiere endpoint: DELETE /api/admin/reportes/:id

Decisión pendiente: ¿implementar hard delete o dejar solo soft delete?

---

## 2. Hard delete de usuarios

Mismo caso que reportes. Actualmente solo soft delete. ¿Se necesita un borrado permanente?

Consideraciones:
- Los reportes del usuario quedan reasignados al admin por defecto (FK ON DELETE SET DEFAULT)
- La auditoría mantiene referencia al usuario
- La función eliminar_cuenta_usuario() ya anonimiza datos personales

---

## 3. Reportes sin coordenadas y lógica de incidentes

La función `asignar_o_crear_incidente` solo agrupa reportes si tienen coordenadas. Si un reporte no tiene latitud/longitud, se crea un incidente nuevo con centro NULL y nunca se agrupa con otros.

Actualmente el formulario de la app obliga coordenadas y barrio, así que en uso normal no debería pasar. Pero si se inserta un reporte directo por query SQL (sin coordenadas), queda como incidente huérfano sin ubicación.

Condiciones para agrupar en un incidente existente (TODAS deben cumplirse):
- Mismo tipo_hurto
- Misma fecha_incidente (exacta)
- Misma franja_horaria (exacta)
- Dentro de 150 metros del centro del incidente

Si alguna no se cumple → se crea incidente nuevo.

Preguntar al asesor:
- ¿Está bien que la BD permita reportes sin coordenadas? (el formulario lo obliga, pero la BD no)
- ¿Se debería agregar NOT NULL a latitud/longitud en la tabla reportes? (rompería reportes rurales sin GPS)
- ¿Los parámetros de agrupación (150m, misma fecha exacta, misma franja) son adecuados o se deberían relajar?

---

[MEJORA A PARTIR DE AQUÍ]

## 4. Mejoras y optimizaciones 

1. **Usuario.**
Nop, ella

- Sí hay un atraco en el momento (mismo día en que se reporta) si se debe mostrar la alerta o baner de hurto que aparece actualmente, pero si es un hurto antiguo a la fecha actual, no mostrar banner. Esto solo aumentaría la alerta del usuario innecesariamente.

- Buscador de barrios para hacer mas facil ver los incidentes si el usuario no sabe la comuna. Lógica de funcionamiento: Toggle Urbano/Rural: El usuario declara explícitamente su contexto y el drawer le responde mostrando lo que es relevante para él. Los 12 chips de comuna se reemplazan por chips de corregimiento cuando toca "Rural". Nunca ve las dos cosas a la vez, no hay saturación. Es la más limpia visualmente y la más honesta con el usuario rural — le dice que la app lo considera.

- Por supuesto tambien debería implementarse en el reporte, solo que las coordenadas ya no serian obligatorias, por eso estas mismas pasaron a ser nullable, aunque si seria obligatorio el barrio. Claro que se va a implementar la logica de barrios y comunas, asi que hay que ver como sale. Pero el toggle tambien cambiaria ya que el mapa deberia leer las coordenadas de los corregimientos, ya no relacionar barrios y comunas, sino veredas y corregimientos.

- Los filtros no deben restablecerse si por ejemplo, yo pongo unos filtros y paso a modo nocturno, deben seguir los que puse, no volver a cero. Mantenerse a menos que el usuario de en el boton de restablecer. -- Explicarme porque se restablecen. 

- El usuario puede editar todos los campos de su reporte. Revisar si, efectivamente le deja manipular todos los campos. 
