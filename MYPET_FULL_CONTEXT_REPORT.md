# MYPET FULL CONTEXT REPORT
**Generado automáticamente tras auditoría de código, configuración y estado.**

## 1. RESUMEN GENERAL

* **Qué es MYPET:** Un juego tipo "hotel de mascotas" virtual donde el jugador gestiona estancias de mascotas, las cuida (comer, beber, jugar, etc.) para mantener sus estadísticas altas, y las devuelve a sus dueños para ganar monedas y mejorar la guardería.
* **Objetivo actual:** Validar mecánicas core, implementar "game feel" a través de minijuegos interactivos para los cuidados, y afianzar la arquitectura Local-First.
* **Estado actual:** Fase MVP (Producto Viable Mínimo) avanzado. El core loop (adoptar -> cuidar -> devolver -> cobrar) funciona. El sistema de persistencia y minijuegos está implementado.
* **Stack Tecnológico:**
  * **Frontend:** Flutter (`^3.11.0` SDK), Dart, motor de físicas/juegos Flame (`^1.38.2`).
  * **Backend:** Java 21, Spring Boot (`4.1.1`), Spring Security, JJWT para autenticación.
  * **Base de datos:** MongoDB Atlas (vía Spring Data MongoDB).
* **Plataformas objetivo:** Principalmente Web y Mobile/Tablet (diseño responsive implementado).
* **Partes Terminadas:** Arquitectura Local-First, autenticación JWT, minijuegos de cuidado, físicas básicas (Flame), sistema de stats aleatorios, core loop de estancias.
* **Partes Pendientes:** Economía, tienda de objetos, inventario de juguetes/comida, mejoras progresivas de nivel infinito.

## 2. ESTRUCTURA COMPLETA DEL PROYECTO

```text
C:\MYPET
├── backend\
│   ├── pom.xml
│   ├── src\main\
│   │   ├── java\com\mypet\backend\
│   │   └── resources\
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       └── application-prod.yml
├── frontend\
│   ├── pubspec.yaml
│   ├── lib\
│   │   ├── app\ (Configuración principal)
│   │   ├── core\ (Constantes, configs)
│   │   ├── data\
│   │   │   ├── local\ (GameState, LocalStorage)
│   │   │   ├── remote\
│   │   │   ├── repositories\ (Local & Remote Repositories, Auth)
│   │   │   └── services\ (GameSyncService)
│   │   ├── features\
│   │   │   ├── auth\ (AuthDialog)
│   │   │   ├── nursery\ (NurseryScreen, Minijuegos)
│   │   │   ├── shop\ (Placeholders)
│   │   │   └── inventory\ (Placeholders)
│   │   └── game\
│   │       ├── mypet_game.dart (Flame Game)
│   │       ├── behaviors\ (Lógica de IA de mascotas en Flame)
│   │       ├── components\ (Mascotas, Clientes, Objetos visuales)
│   │       ├── minigames\ (Resultados de minijuegos y componentes Flame)
│   │       └── models\ (Pet, PetStats, Player, BoardingStay, Customer)
│   ├── docs\qa\ (Informes de desarrollo y QA)
│   └── test\ (Tests unitarios y de widgets)
```

## 3. ARQUITECTURA

* **Organización / Capas:** Patrón de separación de responsabilidades. `features` contiene la UI en Flutter, `game` contiene el lienzo y componentes físicos de Flame, y `data` contiene repositorios y estado.
* **Integración Flutter-Flame:** `GameState` (que extiende `ChangeNotifier`) actúa como puente. Flutter lee el estado e inyecta intenciones (ej. `gameState.playWithPet()`), que a su vez alteran las propiedades que leen los componentes de Flame (`PetGraphicComponent`, `ActionBehavior`) en el loop de actualización (`update()`).
* **Minijuegos:** Los minijuegos de Flutter devuelven un `CareMinigameResult` mediante `Navigator.pop`. `GameState` aplica estos resultados. El minijuego de Flame (jugar) se inyecta por encima de la escena y se comunica a través del callback de completado.
* **Persistencia Local-First:** TODA la acción del jugador altera un estado en memoria (`Player`) que inmediatamente se guarda en disco (SharedPreferences mediante `LocalStorage`) sin esperar red.
* **Sincronización:** `GameSyncService` es notificado por `GameState` de que hay un cambio pendiente. Con un "debounce" de 2 segundos, intenta enviar el JSON serializado a MongoDB. Si falla por falta de internet, se queda en pendiente (`SyncStatus.error` o `SyncStatus.pending`) y se reintentará después. Al recargar la app se carga desde caché y luego se sincroniza el JWT.

## 4. MODELOS Y DATOS

* **`Player`** (`lib/game/models/player.dart`):
  * **Campos:** `id`, `saveVersion`, `revision`, `coins`, `nurseryLevel`, `capacity`, `activePets`, `activeStays`, `completedStays`.
  * **Defecto:** `coins: 100`, `capacity: 4`, versión 1.
  * **Lógica:** Serializa en cascada todas las mascotas y estancias activas.
* **`Pet`** (`lib/game/models/pet.dart`):
  * **Campos:** `id`, `name`, `species`, `personality`, `stats`.
  * **Transitorios:** `currentAction`, `currentActionId`, `currentActionMessage`, `minigameResult`. (No se guardan en JSON).
* **`PetStats`** (`lib/game/models/pet_stats.dart`):
  * **Campos:** `hunger`, `thirst`, `hygiene`, `energy`, `happiness`.
  * **Lógica:** Función `clamp()` restringe valores de 0 a 100. Función factory `PetStats.random()` genera los iniciales.
* **`BoardingStay`** (`lib/game/models/boarding_stay.dart`):
  * **Campos:** `customer`, `petId`, `request`, `startedAt`, `expectedDurationSeconds`, `status`, `satisfaction`, `rewardCoins`.
* **`CareMinigameResult`** (`lib/game/minigames/minigame_result.dart`): Contrato entre minijuego y `GameState`. Transfiere `statChanges`.

## 5. ESTADÍSTICAS DE LAS MASCOTAS (`PetStats`)

* **Rangos:** `0.0` a `100.0`.
* **Decay (Decadencia):** Existe decaimiento pasivo continuo definido en `MyPetGame.update()` cada 5 segundos: hambre (-0.5), sed (-0.6), energía (-0.3), felicidad (-0.2), higiene (-0.4).
* **Efecto en Gameplay:** Determina la satisfacción del cliente al devolver la mascota (de 1 a 5 estrellas) y las monedas ganadas (entre 5 y 50).
* **`PetStats.random()`:**
  * **Base:** Genera un valor aleatorio entre 35 y 75 para todas las stats usando `math.Random()`.
  * **Determinismo:** Permite inyectar la semilla aleatoria para tests unitarios (Testable).

## 6. ESPECIES

Implementadas e inferidas desde `PetStats.random`:
1. **Dog (Perro):** +10 Felicidad, +10 Energía.
2. **Cat (Gato):** -5 Energía, +10 Higiene.
3. **Hamster:** +15 Energía, +10 Hambre (empieza menos hambriento).
4. **Rabbit (Conejo):** +5 Felicidad, +5 Energía.

## 7. PERSONALIDADES

Implementadas en `PetStats.random`:
1. **Juguetón:** -10 Energía (gastó jugando), +10 Felicidad.
2. **Tímido:** -10 Felicidad (miedoso).
3. **Curioso:** -5 Energía, +5 Hambre.
4. **Tranquilo / Dormilón:** +15 Energía.
5. **Travieso:** -15 Higiene (sucio), +5 Felicidad.

## 8. SISTEMA DE CUIDADOS

Todos gestionados a través de `GameState` en `lib/data/local/game_state.dart`. Las acciones activan el watchdog (ActionBehavior en Flame). Si se completa el minijuego, aplica recompensas.

* **Comer:** Activa Minijuego (Flutter). Recompensa proporcional (+8 a +25 hambre, +5 feliz).
* **Bañar:** Activa Minijuego (Flutter). Recompensa (+30 Higiene).
* **Jugar:** Activa Minijuego (Flame). Recompensa (+15 Felicidad, -10 Energía).
* **Mimos:** Activa Minijuego (Flutter). Recompensa (+10 Felicidad).
* **Beber:** Acción automática / simplificada (botón directo). +30 Sed, +2 Feliz.
* **Dormir:** Acción automática. +30 Energía.

## 9. MINIJUEGOS

1. **EatMinigame** (`features/nursery/minigames/eat_minigame.dart`):
   * **Mecánica:** Overlay Flutter. `DragTarget` y `Draggable`. Jugador arrastra 3 porciones de comida al plato.
   * **Salida:** `CareMinigameResult(success: true, statChanges: {'hunger': 25, 'happiness': 5})`.
2. **BathMinigame** (`features/nursery/minigames/bath_minigame.dart`):
   * **Mecánica:** Flutter `GestureDetector` (`onPanUpdate`). Al deslizar el dedo borra una capa de suciedad (opacidad variable) y spawnea partículas de jabón (🫧).
   * **Salida:** `statChanges: {'hygiene': 30}`.
3. **PlayMinigameToy** (`game/minigames/play_minigame_toy.dart`):
   * **Mecánica:** Flame puro. Un componente `ToyComponent` interactivo con `DragCallbacks`. La mascota en Flame abandona su comportamiento base para usar una ruta de intercepción hacia el juguete usando `MoveToEffect`.
   * **Salida:** `statChanges: {'happiness': 15, 'energy': -10}`. 
4. **PettingMinigame** (`features/nursery/minigames/petting_minigame.dart`):
   * **Mecánica:** Flutter `onPanUpdate`. Deslizar spawneará corazones animados (💖) que se desvanecen. Tras 4 swipes termina el juego.

*(Todas manejan cancelación retornando `CareMinigameResult.cancelled()` e ignoran cambios de stats)*.

## 10. GAME FEEL

* **Implementado:** 
  * Físicas y deambulación (`wander_behavior.dart`). 
  * Interrupciones y Watchdog timers (Las acciones en Flame tardan unos segundos, y si algo falla, resetean al estado `idle` evitando cuelgues).
  * Movimientos inter-dependientes (Mascota siguiendo un juguete, Mascota y Cliente llegando juntos a recepción en `finishIncomingSequence`).
  * Iluminación visual (Un efecto de luz de ventana cruzando la pantalla lentamente en `NurseryBackgroundComponent`).
* **Pendiente:** Sonidos. Economía de objetos (los bowls y camas están estáticos en el mapa por ahora).

## 11. UI/UX

* **AuthDialog** (`features/auth/auth_dialog.dart`): Pop-up de Login/Registro para token JWT.
* **NurseryScreen** (`features/nursery/nursery_screen.dart`): Pantalla principal. 
  * Layout Adaptativo: Renderiza `_DesktopLayout` (barra lateral con Grid) o `_MobileLayout` (botones retráctiles y GameWidget ocupando la pantalla superior).
* **PetInfoPanel** (`features/nursery/pet_info_panel.dart`): Muestra barras de progreso estandarizadas para vida/stats y estado de tiempo de estancia.
* **Shop / Inventory**: Funcionalidad planeada, actualmente pantallas esqueleto.

## 12. PROGRESIÓN

* **Capacidad:** Funcional (Límite 4 mascotas).
* **Economía (Monedas):** Funcional (Al entregar la mascota se ganan entre 5 y 50 monedas según las estrellas).
* **Estrellas (Satisfacción):** Funcional (Se basan en un rating sobre las 5 barras de stats de la mascota devuelta).
* **Tienda/Objetos Desbloqueables:** INEXISTENTE / PENDIENTE. (La arquitectura está preparada, pero los inventarios no están conectados ni implementados en UI de forma real).

## 13. PERSISTENCIA Y MONGODB

* **Backend:** Spring Boot (`port 8080`).
* **MongoDB:** Configurado en `application-dev.yml` (localhost) y `application-prod.yml` vía variables de entorno (`MONGODB_URI`, ocultas por seguridad en logs de Render).
* **Colecciones (Backend):** Guardan un Payload JSON (`GameSave`) indexado por un identificador único (JWT Subject) que incluye la "Revisión" para conflictos.
* **Flujo Local-First:** El Frontend confía ciegamente en sus `SharedPreferences`. Al hacer un cambio de monedas o stats, incrementa la revisión y guarda localmente. En background, lanza HTTP POST al backend.
* **Offline:** Funciona perfectamente. Si el backend falla, `GameSyncService` mantiene estado `pending` o `error` y el indicador de UI avisa. Cuando vuelve la conexión, retoma la sincronización.

## 14. TESTS

* **Resultados Actuales:** **FALLIDOS.** 14 pruebas que rompen por una excepción de Flutter Test Framework: `LateInitializationError: Field '_prefs' has not been initialized.` (en `LocalStorage`).
* **Causa:** Las pruebas de `minimalist_e2e_test`, `flame_tap_test`, `stress_actions_test` y `selection_test` no están mockeando correctamente la inicialización estática de `SharedPreferences` que introducimos con el rediseño de `LocalStorage`.
* **Flutter Analyze:** **EXITOSO** (26 advertencias de estilo e imports no utilizados, **0 errores** de compilación). No bloquea el desarrollo.
* **Cobertura:** Extensa. Cubren la máquina de estados, el watchdog, estrés de eventos simultáneos, selecciones, y tap a Flame. 

## 15. DOCUMENTACIÓN EXISTENTE

1. `README.md`: Resumen principal.
2. `docs/qa/gameplay_mobile_capacity_qa.md`: Registro de QA sobre la correcta implementación de la capacidad de mascotas y la adaptación de UI a móviles.
3. `docs/qa/minigames-research.md`: Decisión arquitectónica para mezclar Flutter y Flame sin bloquear el Local-First (usando `CareMinigameResult`).
4. `docs/qa/minigames_complete_report.md`: Checklist confirmando que las Fases 1 y 2 de "Game Feel y Minijuegos" están cumplidas.

## 16. ROADMAP ACTUAL

| FASE | ESTADO | QUÉ INCLUYE | PENDIENTES |
| ---- | ------ | ----------- | ---------- |
| 1. Core Arquitectura | TERMINADO | Backend Spring, JWT, Flame basico, Local-First, State Machine. | - |
| 2. Minijuegos | TERMINADO | Comer, Jugar, Bañar, Mimos, Stats Aleatorios, Limite Capacidad. | - |
| 3. Economía y Tienda | **PENDIENTE** | Sistema de inventario, comprar mejoras, skins. (Inferido) | Diseñar UI real y consumibles. |
| 4. Progresión (Niveles) | **PENDIENTE** | Aumentar capacidad de 4 a más pagando monedas. (Inferido) | Implementar en backend/frontend. |

## 17. PROBLEMAS ACTUALES

* 🟠 **Importante:** Tests rompen por culpa del inicializador de `SharedPreferences`. Se requiere añadir `SharedPreferences.setMockInitialValues({})` en los `setUp` de los tests.
* 🟡 **Menor:** Deprecación de `withOpacity` por `withValues()` en Flutter 3.11+. Imports duplicados o no usados según `flutter analyze`.

## 18. DEUDA TÉCNICA

* **Acoplamiento de Persistencia:** Guardar todo el grafo del `Player` en JSON dentro de `SharedPreferences` es seguro ahora, pero requerirá optimización si el número de objetos almacenados escala enormemente.
* El archivo `nursery_screen.dart` está volviéndose extenso y mezcla la lógica de control del `GameWidget` con el árbol de layouts móviles y de escritorio. (Sería candidato a refactor de UI).

## 19. CONFIGURACIÓN Y EJECUCIÓN

* **Frontend:**
  - Dependencias: `flutter pub get`
  - Ejecución: `flutter run -d chrome` (Apuntará a `http://localhost:8080` por defecto vía `AppConfig.baseUrl`).
* **Backend:**
  - BD: Levantar un MongoDB local o proporcionar `MONGODB_URI` en entorno.
  - Ejecución: `mvnw spring-boot:run` (Dentro de `C:\mypet\backend`).

# CONTEXTO CRÍTICO PARA CONTINUAR EL DESARROLLO

**CUALQUIER IA QUE TOME EL RELEVO DEBE RESPETAR ESTOS PUNTOS:**
1. **Dogma Local-First:** Absolutamente ninguna acción del jugador en el juego debe hacer `await` a una llamada HTTP. TODO cambio altera `Player` en memoria, se guarda en disco local (`save()`), y un servicio en background (`GameSyncService`) se encarga de lidiar con la red. Jamás muestres un spinner de "Cargando" al alimentar a una mascota.
2. **`CareMinigameResult`**: Los minijuegos de Flutter no deben mutar `GameState` directamente internamente. Retornan este objeto al cerrarse vía `Navigator.pop(result)`, permitiendo que `GameState` aplique los incrementos (garantiza el patrón de persistencia).
3. **Máquina de Estados de Flame:** Las animaciones físicas (ej. Caminar hacia el baño) dependen del `ActionBehavior` vigilado por un "Watchdog" de 5 segundos. Si cancelas o mueves cosas manualmente por Flame sin que `GameState` lo sepa, la lógica se desincronizará.
4. **Mascotas transitorias:** Las mascotas que entran (Caminando a recepción guiadas por cliente) se instancian *fuera* de la colección final hasta que termina su animación `finishIncomingSequence`.

## 21. ESTADO FINAL

| Área           | Estado | Confianza | Observaciones |
| -------------- | ------ | --------- | ------------- |
| Arquitectura   | ✅ Estable | ALTA | Flame y Flutter coexisten bien mediante GameState. |
| GameState      | ✅ Completo | ALTA | Soporta CRUD y State Machine robusta. |
| PetStats       | ✅ Completo | ALTA | Factory determinista y aleatoriedad por especies/roles. |
| Especies       | ✅ Implementado | ALTA | 4 Operativas con bonos asimétricos. |
| Personalidades | ✅ Implementado | ALTA | 5 Operativas con roles lógicos. |
| Cuidados       | ✅ Completo | ALTA | Todos los verbos atados a callbacks o UI. |
| Minijuegos     | ✅ Completo | ALTA | Drag/Drop y Swipe implementados. |
| Game Feel      | 🟡 Parcial | MEDIA | Faltan sonidos, aunque animaciones e interrupciones están listos. |
| UI             | ✅ Estable | ALTA | Soporte dual Mobile/Tablet/Desktop fluido. |
| Progresión     | 🟡 Parcial | ALTA | Límite de capacidad y monedas implementado, pero no hay gastador de monedas. |
| Inventario     | ❌ Inexistente | ALTA | Capa esqueleto, sin impacto en DB. |
| Tienda         | ❌ Inexistente | ALTA | Capa esqueleto. |
| MongoDB        | ✅ Estable | ALTA | Conexiones parametrizadas y despliegue a Render correcto. |
| Local-First    | ✅ Sólido | ALTA | Tolerancia a la desconexión total demostrada. |
| Tests          | 🔴 Rotos | ALTA | Errores de mock en `SharedPreferences`. |
| Documentación  | ✅ Buena | ALTA | QA tracks en `/docs/qa`. |
| Roadmap        | 🟡 Parcial | MEDIA | Inferido a partir de placeholders de Tienda/Inventario. |
