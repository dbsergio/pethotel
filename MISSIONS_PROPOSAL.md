# Propuesta Técnica: Sistema de Misiones Diarias (Daily Missions) en Arquitectura Local-First

## 1. Visión General
El objetivo es incorporar un sistema de misiones diarias (e.g. "Baña a 3 mascotas", "Completa 5 estancias de perros") que recompense al jugador con monedas o cosméticos, manteniendo la filosofía Local-First del juego.

Dado que MYPET puede funcionar sin conexión, el sistema debe calcular, progresar y otorgar recompensas *localmente* en el cliente (Flutter) y sincronizar el estado final con el backend cuando haya conexión disponible.

## 2. Estructura de Datos (Modelos)

### 2.1 Misión (Definición estática)
Igual que el `StoreCatalog`, las misiones pueden definirse estáticamente en el cliente para no depender de una conexión en la validación de la lógica.
```dart
enum MissionType { bathePets, completeStays, feedPets, playWithPets }

class MissionDef {
  final String id;
  final String description;
  final MissionType type;
  final int targetAmount;
  final int rewardCoins;
}
```

### 2.2 Progreso de Misión (Estado Dinámico)
Añadiremos un nuevo objeto en el `Player` o un documento independiente `MissionProgress`. Para no afectar dramáticamente a la concurrencia, lo ideal es guardarlo junto a la entidad del jugador si son pocas misiones (ej. 3 diarias).
```dart
class MissionProgress {
  final String missionId;
  int currentAmount;
  bool isCompleted;
  bool rewardClaimed;
  DateTime dateAssigned; // Para saber a qué día corresponde y refrescar
}
```
En el backend (Java), esto se traduciría en una lista `List<Map<String, Object>> dailyMissions` dentro de `GameSave`.

## 3. Lógica de Asignación y Refresco (Local-First)
En un sistema puramente server-authoritative, el servidor asigna misiones cada día a las 00:00 UTC. 
En MYPET, el **cliente** asume la responsabilidad:
1. Al cargar la aplicación, `GameState` verifica la fecha actual del sistema.
2. Si la `dateAssigned` de las misiones actuales es de un día anterior (o no existen misiones), el cliente "roll-ea" (asigna aleatoriamente) 3 misiones nuevas usando un seed basado en la fecha (opcional, para que todos los jugadores tengan las mismas misiones ese día).
3. Esto permite al jugador recibir misiones y jugarlas completamente offline.

## 4. Registro de Progreso (Event Driven)
En lugar de acoplar la lógica de misiones al código de los minijuegos, se puede utilizar el sistema reactivo que ya ofrece `GameState`.
1. Cuando ocurre una acción importante (e.g. `completeBathePet`, `deliverPet`), el `GameState` invoca un evaluador: `_checkMissions(MissionType.bathePets, 1)`.
2. Si el `MissionProgress` correspondiente no está completado, se incrementa `currentAmount`.
3. Si alcanza `targetAmount`, `isCompleted = true`.
4. Se guarda el `Player` y el `GameSyncService` encola la sincronización con el servidor.

## 5. Prevención de Concurrencia y Abusos (Sincronización)
¿Qué ocurre si el jugador abre la web en su iPad y en su móvil simultáneamente sin red, completa misiones en ambos y luego sincroniza?
* El modelo de sincronización actual de MYPET utiliza **Revisiones / Last Write Wins** o un reemplazo autoritario del servidor. 
* Si se mantiene el LWW (`revision`), el progreso que se sincronice último sobrescribirá al otro. Para misiones simples esto es aceptable.
* Si el jugador intenta "hacer trampa" cambiando la fecha del dispositivo, el backend podría rechazar misiones reclamadas en fechas "futuras" respecto al reloj del servidor validando el campo `dateAssigned` o registrando los "claims" en una tabla segura del servidor para evitar doble cobro de la recompensa.

## 6. Siguientes Pasos (Implementación Futura)
1. Definir el catálogo estático de misiones.
2. Modificar el modelo `Player` (Dart y Java) para soportar `dailyMissions`.
3. Crear el panel visual en el HUD (botón con lista desplegable de misiones).
4. Interceptar las finalizaciones de minijuegos y estancias en `GameState` para alimentar el contador.
