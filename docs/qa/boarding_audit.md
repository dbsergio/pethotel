# Auditoría: Fase Vertical Slice de Clientes y Estancias

## 1. Arquitectura Actual

- **Modelos:** Tenemos `Player` (id, coins, capacity, activePets) y `Pet` (id, name, species, personality, stats, action transient state). `Pet` actualmente tiene campos `clientName` y `clientRequest` que pueden extraerse hacia los nuevos modelos para mayor limpieza.
- **Estado Global (`GameState`):** Contiene la lógica central y gestiona el `Player` y `selectedPetId`. Maneja todas las acciones (`feedPet`, `petPet`, etc.). Todo persiste a través de `GameRepository`.
- **UI Flutter (`nursery_screen.dart`):** Usa un layout responsivo (Desktop vs Mobile) y lee de `GameState`. Actualmente la Recepción abre un diálogo que crea una mascota y la inyecta directamente.
- **Motor Flame (`MyPetGame`):** Sincroniza visualmente `activePets`. Usa prioridades (mascotas=10, objetos=5, fondo=0) y gestiona el touch correctamente en `onTapDown` del `PetGraphicComponent`. El movimiento autónomo se maneja con `MovementBehavior` y `WanderBehavior`.

## 2. Archivos a Modificar

- `lib/game/models/player.dart`: Añadir lista de `activeStays` (estancias activas) y `completedStays` (historial mínimo).
- `lib/data/local/game_state.dart`: Añadir lógica de ciclo de vida de estancias (timer corto, aceptar estancia, completar estancia, calcular satisfacción).
- `lib/features/nursery/nursery_screen.dart`: Actualizar el botón de Recepción para procesar estancias. Mostrar indicadores de mascotas listas para recogida. Añadir diálogos de valoración y recompensa.
- `lib/features/nursery/pet_info_panel.dart`: Mostrar el estado de la estancia (tiempo restante, botón para entregar si está listo).
- `lib/game/mypet_game.dart`: Implementar la entrada y salida física de la mascota (animación de entrada y salida hacia la puerta).

## 3. Archivos Nuevos

- `lib/game/models/customer.dart`: Entidad `Customer` (id, name, status).
- `lib/game/models/boarding_stay.dart`: Entidad `BoardingStay` (id, customer, petId, request, startedAt, expectedDuration, status, satisfaction, rewardCoins).
- `lib/features/nursery/stay_completed_dialog.dart`: Tarjeta visual para mostrar la valoración (estrellas) y monedas ganadas.

## 4. Riesgos de Regresión y Mitigaciones

- **Selección de Mascotas:** El uso de `selectedPetId` no debe romperse. La lógica de recogida debe referenciar el `petId` de la estancia, sin depender de la selección actual.
- **Persistencia:** Si se añaden campos al `Player`, la deserialización (`fromJson`) debe ser tolerante a datos antiguos para no crashear con el guardado actual del usuario.
- **Acciones concurrentes:** Las acciones asíncronas no deben interferir si el jugador decide recoger a la mascota justo cuando está ejecutando una acción. La recogida cancelará las acciones actuales de Flame para esa mascota.
- **UI Responsiva:** Los nuevos avisos de "recogida" o diálogos deben testearse en `_DesktopLayout` y `_MobileLayout`.

## 5. Próximos Pasos (Implementación)
1. Crear modelos `Customer` y `BoardingStay`.
2. Actualizar `Player` y persistencia.
3. Modificar `GameState` con timers y cálculo de satisfacción.
4. Adaptar la Recepción y el diálogo de recogida.
5. Sincronizar Flame para la entrada/salida física.
