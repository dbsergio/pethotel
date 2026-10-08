# Investigación: Arquitectura de Minijuegos (Flame & Flutter)

## Referencias Analizadas

### 1. Flame Engine
Flame proporciona un entorno de componentes jerárquicos (FCS) ideal para interactuar con la lógica del juego.
- **Componentes Interactivos:** Uso de mixins como `TapCallbacks` y `DragCallbacks` para interacciones táctiles directas en el lienzo.
- **Efectos:** `MoveToEffect`, `SequenceEffect` para animaciones interpoladas simples (ej. movimiento de juguetes o mascotas).
- **Sistemas de Partículas / Animación:** `SpriteAnimationGroupComponent` permite separar los estados visuales (idle, walking, eating).

### 2. Flutter Pinball (flutter-team-archive)
- **Separación de responsabilidades:** La lógica de estado general de la partida (puntuación, configuración) se maneja en BLoC/Provider (en nuestro caso ChangeNotifier `GameState`), mientras que Flame gestiona exclusivamente la física y presentación.
- **Feedback:** Cuando ocurren eventos en Flame (ej. golpear un bumper), el componente de Flame se comunica con el estado inyectado o notifica un cambio que la UI de Flutter refleja.
- **Overlays:** Flutter Pinball usa widgets de Flutter montados *sobre* Flame (GameWidget overlays) para menús, diálogos o feedback flotante, dejando a Flame el loop de actualización.

### 3. Flutter Casual Games Toolkit
- Define patrones para integrar menús, configuración (sonido, persistencia) y jugabilidad.
- Enseña a no mezclar la interfaz "administrativa" o de menús dentro de Flame, sino usar widgets nativos de Flutter superpuestos, mientras la jugabilidad pura de toque/arrastre se queda en Flame.

## Arquitectura Elegida para MYPET

Basándonos en las referencias, vamos a implementar un patrón híbrido:

1. **`CareMinigameResult`**: Un objeto de datos que representa el resultado de un minijuego (ej. éxito parcial, cancelación).
2. **Desacoplamiento del GameState**: El minijuego NO modifica `GameState` directamente. El minijuego devuelve un `CareMinigameResult` mediante un callback o un `Future`, y luego `GameState` aplica las recompensas o cambios de stats y guarda la partida.
3. **Flutter vs Flame**:
   - **Comer, Baño y Mimos**: Al ser minijuegos estáticos e interactivos, pueden implementarse tanto como *Overlays* de Flutter sobre el juego, o como componentes temporales de Flame. Usaremos componentes temporales superpuestos en la vista de Flutter si requieren widgets estándar (como un "hold to fill" o drag & drop de Flutter), o puramente en Flame usando `DragCallbacks`. Para mantener la ilusión del mundo, utilizaremos **Overlays de Flutter con fondos transparentes** o un **Overlay UI** temporal centrado en la mascota seleccionada.
   - **Jugar**: Debe utilizar **Flame** (moviendo un componente objetivo en el mundo) ya que la mascota reacciona y camina usando la lógica existente en el `MyPetGame`.
   - **Beber / Dormir**: Interacciones nativas de Flutter (Long Press / Hold) en los botones existentes de acciones rápidas.

Esta estrategia aísla la lógica de minijuegos sin perturbar el ciclo de persistencia de `GameState`.
