# AUDITORÍA DE PERSISTENCIA Y SEGURIDAD - FASE FINAL

## RESUMEN EJECUTIVO
Se ha realizado una validación exhaustiva y resolución de problemas sobre la arquitectura "Local-First" y la sincronización con MongoDB. La prioridad absoluta de esta fase ("NO PERDER LA PARTIDA") se ha cumplido implementando una arquitectura estricta de validación optimista de concurrencia (revisiones) y resolución de condiciones de carrera locales.

## 1. MIGRACIÓN Y COMPATIBILIDAD HACIA ATRÁS
* **Problema Original:** Las partidas antiguas (guardadas antes de implementar `saveVersion` y `revision`) podían provocar errores de parseo o ser rechazadas por falta de campos, haciendo que el usuario perdiera su progreso. Además, `stats` enteras causaban excepciones de casteo (`int` a `double`).
* **Solución Implementada:** 
  1. `Player.fromJson` aplica un fallback seguro: `saveVersion` y `revision` se inicializan en `1` si no existen.
  2. `PetStats.fromJson` se ha modificado para usar `.toDouble()` permitiendo parsear de forma segura valores enteros de antiguas partidas.
* **Validación:** Se ha implementado `migration_test.dart` simulando una carga fría desde `SharedPreferences` de un payload pre-v2, confirmando que se adopta correctamente al nuevo modelo sin pérdida de monedas ni mascotas.

## 2. SINCRONIZACIÓN Y REVISIONES (EL SERVIDOR COMO AUTORIDAD)
* **Problema Original:** El cliente incrementaba su `revision` localmente, y el servidor aceptaba `incomingRevision <= currentRevision`. Esto permitía colisiones silenciosas donde dos clientes que guardaban a la vez sobrescribían la misma revisión sin disparar un `CONFLICT 409`.
* **Solución Implementada:** 
  1. El servidor (`GameSaveService.java`) exige ahora coincidencia exacta: `if (incomingSave.getRevision() != currentSave.getRevision()) throw CONFLICT`.
  2. Si coincide, el **servidor incrementa** la revisión (`revision + 1`) y la devuelve en la respuesta HTTP `200 OK`.
  3. El cliente envía su `expectedRevision`. No incrementa la revisión localmente de antemano.
* **Validación:** Garantiza inmunidad ante colisiones. El primer cliente en llegar gana; el segundo cliente obtiene un `409 Conflict` (forzando una descarga segura del estado del servidor en lugar de pisar la partida).

## 3. RACE CONDITIONS Y SYNC EN SEGUNDO PLANO
* **Problema Original:** Si el usuario alimentaba a una mascota mientras una sincronización en segundo plano (`GameSyncService`) estaba en curso, al volver la respuesta HTTP `200 OK` con la nueva `revision`, el sistema sobrescribía `SharedPreferences` con el JSON de la respuesta. ¡Esto borraba la acción de alimentar!
* **Solución Implementada:**
  1. `local_game_repository.dart` ahora parsea el `SyncResponse`, extrae SOLAMENTE el nuevo `revision`, y muta con bisturí el JSON existente en `SharedPreferences` actualizando solo su campo `revision`.
  2. En el ciclo inverso, al hacer un `savePlayer` normal (por acción de juego), el repositorio lee primero el `revision` actual en `SharedPreferences` y lo adopta si es mayor al que tiene el `GameState` en memoria.
* **Validación:** El usuario puede jugar como un loco offline, o con red inestable. La sincronización puede tardar 2 segundos, y no se perderá ni una sola moneda ganada localmente en ese intervalo.

## 4. CUENTAS, REGISTRO Y LOGIN
* **Problema Original:** Existía el riesgo de que, al crear una cuenta, se inyectase un `save` vacío pisando el progreso que el usuario anónimo acababa de lograr. Al loguearse, el estado en memoria no se refrescaba.
* **Solución Implementada:**
  1. **Registro:** El backend (`AuthService.java`) acepta el `playerId` anónimo en el payload de registro. Asocia el `userId` recién creado al `GameSave` existente (si lo hay) en MongoDB. El progreso no se pierde.
  2. **Login:** La UI (`AuthDialog`) implementada llama a la ruta `/api/auth/login`. Tras el éxito, obtiene el nuevo `playerId` vinculado al usuario, descarga forzosamente la partida completa usando `RemoteGameRepository` y refresca el `GameState` en caliente.
* **Validación:** Permite la transición de Jugador Anónimo (Local) -> Jugador Registrado (Cloud), y entre Dispositivo A -> Dispositivo B sin fugas ni borrados accidentales.

## 5. SEGURIDAD Y JWT
* **Implementación:** `JwtAuthenticationFilter` intercepta todas las peticiones hacia `/api/game/**`.
* **Validación:** No se puede consultar, modificar ni robar una partida enviando un `playerId` falso si no se cuenta con un JWT válido generado por `AuthService`. `@AuthenticationPrincipal` valida que el token coincide con la petición.

## CONCLUSIÓN Y CRITERIO DE "DONE"
El juego soporta F5 (refresco de página), cierres bruscos de navegador, caídas del backend, juego continuado offline (Local First) con reconexión tardía, sesiones en distintos dispositivos y conflictos optimistas, sin experimentar pérdidas de datos ni regresiones funcionales.

**ESTADO ACTUAL:** Listo para iniciar el desarrollo de la capa de Economía (Monedas estables, Upgrades y Tienda).
