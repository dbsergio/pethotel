# Investigación de Input en Flame y Flutter

## 1. Flame (Repositorio Oficial)
* **Patrón utilizado:** En Flame 1.x (>= 1.8), el sistema de eventos táctiles se maneja mediante mixins. El mixin preferido es `TapCallbacks`.
* **Por qué es correcto:** Según la documentación oficial y ejemplos como `gesture_hitboxes_example.dart`, cualquier `PositionComponent` puede recibir eventos táctiles mezclando `TapCallbacks`. No es necesario (y de hecho se desaconseja si no se necesita) añadir `TapCallbacks` al `FlameGame` raíz, ya que el motor de Flame registra automáticamente los detectores de gestos en el `GameWidget` si detecta al menos un componente en el árbol que utilice `TapCallbacks`.
* **Archivos de referencia:** `flame/examples/lib/stories/input/tap_callbacks_example.dart`.
* **Propagación:** Flame entrega el evento al componente más profundo (hoja) que contenga el punto (`containsLocalPoint`). Si ese componente no consume el evento, burbujea hacia arriba. Si el padre (ej. `MyPetGame`) intercepta `onTapDown` y no lo propaga, puede romper el flujo.
* **onTapDown vs onTapUp:** La documentación señala explícitamente que si la posición del componente o del dedo cambia demasiado, un `onTapDown` puede terminar en `onTapCancel` en lugar de `onTapUp`. Para interfaces reactivas en movimiento, a menudo es más fiable reaccionar en `onTapDown`.

## 2. Pinball (flutter-team-archive/pinball)
* **Patrones arquitectónicos interesantes:** El juego Pinball de Google divide claramente el estado de Flutter del de Flame. Los componentes interactivos (como los flippers o el lanzador) utilizan mixins de input específicos de Flame (`Tappable` en versiones antiguas, equivalente a `TapCallbacks` hoy).
* **Jerarquía:** No colocan overlays invisibles encima del canvas para detectar toques. Dejan que el `GameWidget` reciba el evento puro y Flame se encarga del hit testing basándose en el `size` y la `position` de los bodies.

## 3. Conclusión para MYPET
* **Configuración óptima:** Solo `PetGraphicComponent` debe tener `TapCallbacks`. `MyPetGame` NO debe tener `TapCallbacks` a menos que queramos detectar toques en el fondo vacío.
* **Evento de selección:** Dado que las mascotas se mueven (`WanderBehavior`), el usuario puede rozar el ratón al hacer clic, convirtiendo el `onTapUp` en un `onTapCancel` nativo del navegador. La selección de mascota debe ocurrir inmediatamente en **`onTapDown`** para garantizar una respuesta táctil impecable y evitar clics perdidos.
* **Hitbox:** Debemos asegurar que el `size` del componente corresponda estrictamente al gráfico, y que su `containsLocalPoint` funcione de manera predeterminada sin modificaciones extrañas.
