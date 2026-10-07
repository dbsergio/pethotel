# Flame Polish & Game Feel Research

## 1. Flame Components & Effects
- **Components**: Usar `PositionComponent` como base y encapsular las representaciones físicas.
- **Effects**: Utilizar `MoveToEffect`, `SequenceEffect`, `ScaleEffect` para no tener que calcular interpolaciones (`lerp`) manualmente dentro del método `update()`.
- **SpriteAnimationGroupComponent**: Ideal para personajes que tienen múltiples estados (`idle`, `walking`, `eating`, etc.). Se le asocia un map de animaciones y una variable de estado.

## 2. Lecciones de Flutter Pinball
- **Separación Lógica/Visual**: Flame y Flutter deben estar desacoplados. La lógica se mantiene en Bloc/Provider (en nuestro caso `GameState`) y Flame lee este estado pero se encarga solo del renderizado y el movimiento interpolado suave.
- **Transiciones y Feedback**: Usar partículas sencillas (`ParticleSystemComponent`) o efectos visuales cuando un evento ocurre (ej. cobrar monedas). 
- **Z-Index (Priority)**: Es importante mantener una jerarquía para que los clientes, mascotas, objetos y paredes se dibujen correctamente ordenados según el eje Y.

## 3. Plan de Aplicación a MyPet
- **CustomerComponent**: Nuevo componente Flame para representar visualmente al dueño, independiente de la lógica económica. Usará Effects para entrar y salir.
- **Efectos de Feedback**: TextComponent efímeros que suben y se desvanecen (ej. "+Felicidad") en el momento de completar una acción.
- **Idle animations sutiles**: Componentes de `PetGraphicComponent` que utilicen `MoveEffect.by` y `ScaleEffect.by` repetitivos muy suaves para simular respiración.
