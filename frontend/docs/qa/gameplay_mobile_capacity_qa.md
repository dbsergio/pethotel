# QA: Gameplay, Capacidad y HUD Móvil

Este documento registra los cambios de jugabilidad implementados y cómo validarlos.

## 1. Capacidad de la Guardería
- **Cambio:** Se ha incrementado la capacidad máxima de la guardería de 2 a 4 mascotas.
- **Implementación:** 
  - `Player` modificado para tener `capacity: 4` por defecto.
  - El botón de recepción de `NurseryScreen` se ha actualizado para mostrar el texto `Ocupación: X / 4`.
  - Cuando se alcanzan las 4 mascotas, el botón de recepción desaparece y en su lugar se muestra el aviso en rojo: `Guardería llena (4/4)`.
- **Prueba:**
  1. Iniciar sesión y aceptar 4 mascotas.
  2. Comprobar que al aceptar la cuarta mascota, el botón desaparece.
  3. Tras entregar una mascota, el texto debe volver a ser `Ocupación: 3 / 4` y el botón reaparecer.

## 2. Duración de la Estancia y Timings
- **Cambio:** La estancia estándar dura ahora 5 minutos (300 segundos). Se configura centralizadamente mediante variables de entorno (con fallback a 300s).
- **Implementación:**
  - Se ha añadido `AppConfig.boardingStayDurationSeconds` y `AppConfig.pickupDelaySeconds`.
  - `GameState.adoptPet` ahora calcula la duración esperada usando este valor en lugar del anterior de 60 segundos.
- **Prueba:**
  1. Recibir una mascota.
  2. Verificar en el panel (expandido en móvil) que aparece el estado `⏱️ Estancia en curso`.
  3. Esperar 5 minutos.
  4. Comprobar que transcurrido el tiempo, el estado cambia a `📦 Lista para entregar` con el subtexto "El dueño viene de camino...".

## 3. Retraso en la Llegada del Dueño (Pickup Delay)
- **Cambio:** El cliente ya no se genera (spawnea) inmediatamente cuando la estancia termina.
- **Implementación:**
  - Tras terminar el temporizador (`readyForPickup`), MyPetGame espera 15 segundos (`pickupDelaySeconds`) antes de hacer caminar al cliente hacia la puerta.
  - Una vez el cliente llega al centro de la guardería, el estado de la estancia pasa a `StayStatus.pickingUp`.
  - El panel de mascota reacciona al nuevo estado mostrando `✅ El dueño ha llegado` y habilitando el botón de `ENTREGAR MASCOTA`.
- **Prueba:**
  1. Al expirar la estancia de una mascota, observar que el cliente no entra de inmediato.
  2. Leer en el panel: `El dueño viene de camino...`.
  3. A los 15 segundos, el cliente entra y camina hacia el centro.
  4. Una vez en posición, la UI se actualiza permitiendo entregar la mascota.

## 4. Nuevo HUD Móvil Compacto
- **Cambio:** Se ha rediseñado la interfaz móvil para no saturar la pantalla, permitiendo ver el juego detrás del HUD.
- **Implementación:**
  - El layout inferior de móvil (`_BottomHud`) ha sido convertido a un panel condicional `AnimatedContainer`.
  - Por defecto, muestra una barra compacta (Avatar, Nombre, Acción actual y stats mini de Energía y Felicidad) junto al carrusel horizontal de acciones, ocupando apenas un ~25-30% de la pantalla.
  - Al hacer tap sobre este panel inferior o al deslizar hacia arriba, se expande para mostrar los detalles y estadísticas completas de la mascota (idéntico al panel de escritorio).
- **Prueba:**
  1. Entrar desde un dispositivo móvil o redimensionar el navegador.
  2. Seleccionar una mascota.
  3. Verificar que aparece una barra inferior pequeña y que el juego se ve claramente.
  4. Pulsar sobre la tarjeta pequeña; esta debe expandirse suavemente para mostrar todos los datos de la mascota.
  5. Deslizar hacia abajo o volver a pulsar para contraer.
