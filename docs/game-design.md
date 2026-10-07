# MYPET - Game Design Document

## 1. Concepto
Mascota virtual relajante para navegadores. Permite adoptar, cuidar y jugar con una mascota. No hay penalización por cerrar el juego (las estadísticas solo bajan mientras se juega).

## 2. Mascotas
Inicialmente 4 opciones:
- **Perro**: Juguetón, sociable, cariñoso.
- **Gato**: Independiente, dormilón, curioso.
- **Hámster**: Energético, curioso, activo.
- **Conejo**: Tranquilo, sensible, cariñoso.

## 3. Estadísticas
- Hambre (0-100)
- Sed (0-100)
- Higiene (0-100)
- Energía (0-100)
- Felicidad (0-100)

## 4. Acciones (Botones de interacción)
- **Comer**: +20 Hambre, +3 Felicidad
- **Jugar**: +15 Felicidad, -10 Energía
- **Bañar**: +30 Higiene
- **Dormir**: +30 Energía

## 5. Economía
El jugador empieza con 100 monedas (`coins`). Las monedas se usarán para la tienda en el futuro (alimentos premium, juguetes, decoraciones).

## 6. Habitaciones
Actualmente existe la guardería (Nursery). Más adelante se añadirán habitaciones separadas:
- Habitación principal
- Zona de comida
- Zona de baño
- Zona de juego
- Zona de descanso
- Tienda

## 7. Eventos y Recompensas
A implementarse en la siguiente iteración. Pequeños eventos aleatorios recompensarán al jugador con monedas o aumentos de felicidad.
