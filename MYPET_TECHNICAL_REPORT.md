# MYPET - Informe Técnico y Estado del Proyecto

## 1. Visión General y Arquitectura
MYPET es un juego casual de mascotas virtuales diseñado con una arquitectura **Local-First**, lo que significa que el juego es completamente funcional de forma local en el dispositivo del usuario, y sincroniza su estado de forma transparente en segundo plano.

### Stack Tecnológico
- **Frontend (Cliente):** Flutter + Flame Engine (para el renderizado de mascotas, físicas y animaciones).
- **Backend (Servidor):** Spring Boot (Java) expone una API REST para sincronizar el estado.
- **Despliegue:** 
  - Backend: Render (Web Service).
  - Frontend: Render (Static Site) o Github Pages (actualmente publicado desde el repo de frontend).

### Persistencia Local
La capa de datos se divide en repositorios abstractos:
- `LocalGameRepository`: Interactúa con `shared_preferences` para almacenar el JSON del `Pet` y del inventario del usuario.
- `RemoteGameRepository`: Interactúa con el backend Spring Boot vía HTTP.

## 2. Motor de Sincronización (Sync)
El sistema de sincronización está diseñado para manejar pérdida de conexión y conflictos:

- **Optimistic UI:** El estado de `GameState` se actualiza instantáneamente en el cliente.
- **`sync_pending`:** Un flag booleano persistido que indica si hay cambios locales que no han sido enviados al servidor. Si la app se cierra sin internet, al volver a abrir intentará sincronizar de nuevo porque `sync_pending == true`.
- **`revision`:** Un contador de control de versiones. El cliente envía su revisión. Si el servidor tiene una mayor, se genera un estado HTTP 409 Conflict y el cliente debe resolverlo (por defecto, la estrategia actual prioriza el servidor, o realiza un merge si se configura).

## 3. Game Feel y Arte Procedural

### Arte de Especies Vectoriales
MYPET no utiliza recursos `.png` ni `.jpg`. Todas las mascotas se renderizan programáticamente en Flame usando `VectorShapes`.
- **Diferenciación de Especies:** El componente `PetGraphicComponent` genera la forma del cuerpo, las orejas, patas, cola y proporciones físicas dinámicamente dependiendo de la `species` (perro, gato, conejo, hámster).
- **Animaciones Únicas:** Las animaciones se han especializado por especie. Por ejemplo, los conejos botan más alto al andar y mueven su nariz al estar inactivos (idle), los gatos tienen un movimiento de cola suave pero marcado, y los hámsteres tienen patas más cortas y una respiración acelerada.

### Audio Manager (`AudioService`)
Se ha integrado el paquete `flame_audio` para la gestión de sonido.
- El sistema está pre-configurado para no fallar si los archivos de audio aún no han sido incluidos (flag `_hasRealAssets`).
- `AudioService` se inyecta en el árbol de widgets usando `Provider` y proporciona métodos semánticos (`playUiTap`, `playShopPurchase`, `playActionSleep`, `playBgm`, etc.).
- Las preferencias de audio (BGM/SFX on/off) persisten usando `shared_preferences`.

## 4. Minijuegos y Drag & Drop
El núcleo del "Cuidado" (Care) se basa en una arquitectura de Minijuegos:

- Las acciones principales (Comer, Beber, Bañar, Mimos, etc.) abren un minijuego modal.
- Todos comparten la estructura base `DragDropMinigame` o `ActionMinigame`.
- En `EatMinigame` y `DrinkMinigame`, el usuario arrastra la comida/agua al cuenco. Para evitar fallos en móviles, el componente `DragTarget` tiene hitboxes extendidos.
- Al concluir un minijuego (ej. `CareMinigameResult`), se actualizan los stats y si es un éxito rotundo, se bonifica al jugador con monedas (`rewardCoins`).

## 5. Estado Actual
Todas las pruebas de la Fase 4 y el pulido actual (Game Feel, Especies, Audio, Transiciones) **han sido completadas y todos los tests (`flutter test`) pasan exitosamente**.
La aplicación compila correctamente y la experiencia visual es significativamente superior, con transiciones suaves en las pantallas de Tienda e Inventario y un comportamiento reactivo.

## 6. Siguientes Pasos Recomendados (Next Steps)
1. **Activar Audio Real:** Proporcionar los archivos mp3 (como `bgm_nursery.mp3`, `ui_tap.mp3`, etc.), depositarlos en `assets/audio/` y cambiar `_hasRealAssets` a `true` en `AudioService`.
2. **Navegación Táctil en iPad (Pan & Zoom):** Implementar la lógica de cámara (`CameraComponent`) que fue aplazada para permitir arrastrar la vista de la guardería cuando el espacio supera el tamaño de la pantalla.
3. **Despliegue de Validación:** Realizar un commit y push del frontend actual a Render para QA funcional manual en dispositivos físicos.
