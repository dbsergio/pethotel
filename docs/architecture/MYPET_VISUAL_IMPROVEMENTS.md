# MYPET - Mejoras Visuales Pendientes (Fase 4)

El core loop, la economía, el inventario local y la sincronización con el backend ya están implementados y estabilizados. La siguiente fase se enfocará íntegramente en pulir el "Game Feel" y hacer de MYPET una experiencia mucho más atractiva visualmente.

A continuación, se documentan las áreas técnicas clave que requieren atención en la Fase 4:

## 1. Animaciones de Mascotas (SpriteAnimationGroupComponent)
Actualmente, las mascotas utilizan emojis (`Text`) como placeholders de representación gráfica.
- **Implementación técnica:** Migrar `PetGraphicComponent` a `SpriteAnimationGroupComponent` de Flame.
- **Estados necesarios:** 
  - `idle` (respiración suave)
  - `walking` (caminando hacia objetivos)
  - `eating` / `drinking` (interactuando con los cuencos)
  - `sleeping` (Zzz animados)
  - `playing` (saltando feliz)
  - `bathing` (sacudiéndose)

## 2. Transiciones y Movimiento Interpolado
- **Caminatas más fluidas:** Actualmente, se usa un `MoveToEffect` lineal. Añadir aceleración/desaceleración (Easing) y asegurarse de que la mascota mire hacia la dirección a la que camina (`flipHorizontally()`).
- **Transiciones de minijuegos:** Hacer que la cámara de Flame o la UI haga una transición (Fade / Scale) en lugar de lanzar el diálogo abruptamente.

## 3. Feedback Visual de Acciones (Efectos de Partículas y Texto)
Cuando se complete una acción, una compra o el consumo de un objeto:
- **Floating Text Component:** Mostrar textos flotantes (`+20 ❤️`, `+10 ⚡`, `-50 💰`) que se desvanezcan hacia arriba.
- **ParticleSystemComponent:**
  - Al completar el minijuego del baño, emitir partículas de burbujas.
  - Al ganar dinero o cobrar un cliente (`deliverPet`), soltar partículas de monedas cayendo.
  - Al usar un consumible, emitir chispas alrededor de la mascota.

## 4. UI de Economía e Inventario Dinámica
- Añadir micro-interacciones a los botones (como el rebote de `CoinCounterWidget` cuando se incrementan/disminuyen monedas).
- Mostrar la reducción de los items en el inventario con una pequeña animación (shake o scale down).

## 5. Sensación General de Juego (Game Feel)
- **Shaders y Post-processing (Flame):** Aplicar luces sutiles basándose en el ciclo de día/noche.
- **Sonidos:** Hookear paquetes de `flame_audio` a los eventos (campana de la puerta, monedas, comer, ladridos/maullidos, burbujas).
