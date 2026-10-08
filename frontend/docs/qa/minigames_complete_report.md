# QA Report: Sistema de Minijuegos y Stats Aleatorios

## Resumen Ejecutivo
Se ha implementado la Fase 1 y 2 de "Game feel y minijuegos" con éxito. Se introdujo una arquitectura basada en `CareMinigameResult` que permite desacoplar los minijuegos de Flutter de la lógica de estado de `GameState`. Además, se implementó un sistema de stats iniciales aleatorios con modificadores basados en personalidad y especie.

## Objetivos Cumplidos

### A. Stats Iniciales Aleatorios
- Modificado `PetStats` añadiendo la factoría `PetStats.random()`.
- Generación de stats iniciales entre 35 y 75.
- Soporte inyectado para semillas `math.Random()` garantizando el determinismo en pruebas.
- Bonificadores añadidos:
  - **Por Especie**: (e.g. los perros inician con +10 energía/felicidad, los gatos -5 energía/+10 higiene).
  - **Por Personalidad**: (e.g. Juguetón: -10 energía/+10 felicidad, Dormilón: +15 energía).

### B. Arquitectura `CareMinigameResult`
- Creado `minigame_result.dart` (soporta éxito, cancelación y modificadores de stats).
- Actualizado `GameState` para recibir `CareMinigameResult` opcionalmente en métodos como `feedPet`, `bathePet`, `playWithPet`, y `petPet`.
- Las recompensas ya no están "hardcodeadas" en `GameState`, provienen del éxito o esfuerzo del minijuego.

### C. Minijuegos Implementados
1. **Comer (EatMinigame)**:
   - Overlay de Flutter.
   - Mecánica `DragTarget`. La jugadora arrastra 3 porciones de comida (🍖) a un tazón.
   - Recompensas proporcionales: de +8 a +25 de hambre dependiendo del éxito.
2. **Bañar (BathMinigame)**:
   - Overlay de Flutter. Touch/Swipe friendly.
   - La jugadora utiliza gestos de `onPanUpdate` (Drag) sobre la mascota sucia.
   - El sucio desaparece gradualmente basado en la distancia del swipe. Genera burbujas.
   - Recompensa: +30 Higiene.
3. **Jugar (PlayMinigameToy)**:
   - Implementado *nativamente* en Flame (`PlayMinigameToy` como Component).
   - Componente arrastrable (DragCallbacks).
   - La mascota en Flame ajusta su ruta dinámicamente persiguiendo el juguete.
   - Al tocar el juguete 4 veces, termina y devuelve recompensa.
   - Actualizado `ActionBehavior` para no crear conflictos de interpolación.
4. **Mimos (PettingMinigame)**:
   - Overlay de Flutter. Touch/Swipe friendly.
   - La jugadora desliza el dedo sobre la mascota.
   - Genera partículas animadas (corazones 💖) cada vez que se detecta un swipe.
   - Requiere 4 interacciones para completar. +15 Felicidad.
5. **Beber / Dormir**:
   - Mantenidas las interacciones simples y directas según lo solicitado por el usuario ("simplificado").

## Pruebas Realizadas (Checklist)
- [x] Las mascotas inician con atributos aleatorios y se persisten en MongoDB Local-First.
- [x] Cerrar un minijuego (botón X) envía un `CareMinigameResult.cancelled()` e ignora el gasto de recursos o actualización de estado (evita perder recursos).
- [x] El minijuego de *Jugar* funciona dentro del contexto `GameWidget` usando `DragCallbacks` y coordina con `PetGraphicComponent`.
- [x] Los overlays de Flutter no interrumpen los estados activos ni cuelgan `GameState`.
- [x] Compilación exitosa y libre de errores de lint en Flutter (`dart analyze`).

## Conclusión
La experiencia de juego se siente interactiva, física y táctil, ideal para móviles e iPad, sin requerir una reestructuración dramática de Flame ni afectar la robusta arquitectura Local-First existente.
