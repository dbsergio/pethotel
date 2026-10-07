# Arquitectura de Persistencia y Cuentas (MYPET)

## 1. Introducción
El objetivo de esta arquitectura es **blindar la partida de la jugadora**. 
La filosofía "Local First" dicta que el juego se juega principalmente desde el estado local, y la nube (MongoDB) actúa como una copia de seguridad y medio de transporte entre dispositivos.

## 2. Arquitectura General
* **Frontend (Flutter)**: Mantiene el estado en memoria (`GameState`), lo guarda en `SharedPreferences` (LocalGameRepository) y notifica al servicio de sincronización (`GameSyncService`).
* **Backend (Spring Boot)**: Expone endpoints `/api/auth` y `/api/game/save`. Verifica tokens JWT y valida las colisiones de versión (Optimistic Concurrency).
* **Base de Datos (MongoDB Atlas)**: Almacena las cuentas de usuario y los documentos completos de `GameSave`.

## 3. Identificadores y Cuentas
* `playerId`: Identificador estable UUID que representa la "partida" (el progreso). Se asigna la primera vez que se abre el juego.
* `userId`: Cuando la jugadora crea una cuenta, la cuenta de usuario se vincula a este `playerId`. Si inicia sesión en otro dispositivo, descargará la partida asociada a su cuenta y sobrescribirá su `playerId` local con el `playerId` de la nube.

## 4. Estructura del Save (GameSave)
El documento en MongoDB es una representación 1:1 del JSON completo del `Player` en Flutter, con metadatos adicionales:

```json
{
  "_id": "user-uuid-or-player-uuid",
  "playerId": "...",
  "saveVersion": 1,
  "revision": 12,
  "syncPending": false,
  "createdAt": "...",
  "updatedAt": "...",
  "coins": 250,
  "capacity": 2,
  "activePets": [...],
  "activeStays": [...],
  "completedStays": [...]
}
```

## 5. Control de Revisiones (Optimistic Concurrency)
Cada vez que el frontend sube un save, incrementa `revision = local_revision + 1` y manda la `revision` esperada anterior.
Si el backend detecta que la revisión enviada no coincide con la base de datos (por ejemplo, `backend_rev = 14`, pero el front manda `12`), rechaza la sincronización (HTTP 409 Conflict). 
En caso de conflicto, el frontend alerta a la jugadora para que resuelva si prefiere la versión local o la de la nube.

## 6. Sincronización Local First
1. Acción en el juego (ej. ganar monedas).
2. `GameState` actualiza memoria.
3. Se guarda en `SharedPreferences` inmediatamente. `syncPending = true`.
4. El `GameSyncService` reacciona, y lanza un debounced POST a `/api/game/save`.
5. Si falla por falta de internet, se queda en `syncPending = true`.
6. Al volver internet, se reintenta.

## 7. Migración de Partidas Locales
Al iniciar el juego o crear una cuenta:
1. Se recupera el save local (`player_data_$playerId`).
2. Si el save no tiene `saveVersion`, se asume V1 y se migra manteniendo monedas, mascotas, y estancias.
3. Al loguearse, si hay un save remoto y no hay local, se descarga. Si hay ambos, se valida la revisión.
