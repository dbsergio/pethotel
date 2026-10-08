# Propuesta de Arquitectura: Economía, Inventario y Tienda (Fase 3)

## 1. ESTADO ACTUAL Y PLAYER

Actualmente, las monedas se encuentran definidas en el modelo `Player` (en Flutter y su homólogo `GameSave` en Spring Boot).
* **Modificación:** Se añaden en `GameState.deliverPet()` tras finalizar una estancia. No existen métodos dedicados `addCoins()` o `deductCoins()`.
* **Guardado y Serialización:** `Player.toJson()` mapea `coins`. `GameRepository` (a través de `LocalStorage` vía SharedPreferences) lo persiste localmente.
* **Sincronización:** `GameSyncService` lo envía al backend dentro del objeto `GameSave`.
* **Validación:** No existe actualmente validación de saldos ni en frontend ni en backend. El backend aplica "Optimistic Concurrency Control" mediante el campo `revision` para evitar Race Conditions, pero confía ciegamente en el payload JSON.
* **Recompensas Actuales:** Calculadas en base a las estadísticas de la mascota. El cálculo real genera un `score` que se traduce a estrellas (1-5). Una mascota de 1 estrella otorga **10 monedas** y una de 5 estrellas otorga **30 monedas**.

## 2. INVENTARIO ACTUAL Y TIENDA

Se ha detectado la existencia de las pantallas `InventoryScreen` y `ShopScreen` en la carpeta `features`, pero ambas contienen únicamente *placeholders* estáticos de UI. No hay modelos de datos para `Item`, `Inventory` ni `Consumable`.

## 3. BACKEND EXISTENTE REUTILIZABLE

El backend Spring Boot expone un esquema basado fuertemente en documentos.
* Las entidades clave son `GameSave` y `User`.
* `GameController` solo expone `/save` (GET y POST) sin infraestructura explícita para economía.
* **Reutilización:** La filosofía de un único documento (`GameSave`) es ideal para el rendimiento. En lugar de crear complejas tablas relacionales para el inventario, seguiremos integrando los datos de progreso directamente dentro de `GameSave`.

## 4. LOCAL-FIRST: FLUJO DE COMPRAS

Respetando el dogma de la arquitectura, una compra debe ejecutarse 100% de forma síncrona en memoria sin esperas de red.

**Flujo propuesto:**
1. Usuario pulsa "Comprar [Objeto]" en la UI.
2. `GameState` comprueba localmente `player.coins >= item.price`. (Si no, excepción o rechazo inmediato).
3. Se restan las monedas localmente y se añade `{itemId: cantidad}` al inventario.
4. Se ejecuta `localRepository.save(player)` de inmediato.
5. Se notifica a los listeners y la UI muestra la transacción finalizada al instante.
6. Se llama a `gameSyncService.markPending()`.
7. En segundo plano, el JSON actualizado se envía a `/api/game/save`.

## 5. MODELO DE DATOS PROPUESTO (Sin implementar)

Para mantener la sencillez del documento MongoDB actual:

* **`Item` (Estático en Cliente y Servidor):** No se guarda en base de datos de usuarios. Existirá un catálogo hardcodeado (ej. enum o clase estática) que define: `id`, `name`, `type` (consumable, permanent), `effectValue`, y `price`.
* **`Inventory` (Dentro de `Player`):**
  Un simple `Map<String, int>` que mapea `itemId -> cantidad`.
  *Ventaja:* Extremadamente barato de serializar, cabe perfectamente en el `GameSave` sin crear colecciones huérfanas y mantiene atómica la sincronización local/remota.
* **Mejoras (`Upgrades`):**
  Solo números enteros que representan niveles dentro de `Player`. Por ejemplo, `capacity` o `nurseryLevel`.

## 6. ECONOMÍA

Dado que una mascota promedio rinde ~20 monedas por estancia:
* **Consumibles (Comida, Jabón rápido):** ~15 a 30 monedas. Deberían consumir una gran parte de los ingresos para evitar inflación rápida.
* **Mejora de Capacidad (Nivel 2, para tener 5 mascotas):** ~500 monedas (requiere unas 25 estancias exitosas, es un objetivo a medio plazo).
* **Mejora de Capacidad (Nivel 3, para 6 mascotas):** ~1200 monedas.

## 7. TIENDA

La tienda `ShopScreen` tendrá dos pestañas/categorías iniciales (MVP):
1. **Consumibles:** Objetos de un solo uso que recuperan estadísticas al instante sin esfuerzo temporal (ej. Snacks, Pelotas premium, Jabones rápidos).
2. **Mejoras Permanentes:** Incremento de Capacidad (slots de mascotas permitidas a la vez en la guardería).
*(Los cosméticos se diferirán a fases posteriores de monetización)*.

## 8. INTERACCIÓN CON LOS MINIJUEGOS (VITAL)

Para no inutilizar los minijuegos ya programados:
* Los **minijuegos** deben seguir siendo la forma *gratuita* y más eficiente de lograr una puntuación perfecta, pero requieren tiempo del usuario.
* Los **consumibles** costarán dinero. Permiten salir del apuro (ej. tienes la guardería llena y una mascota se va ya y tiene hambre), pero penalizan económicamente. Un consumible podría subir `hunger` a tope en 0 segundos, pero gastaste tu margen de beneficio.
* Esto genera toma de decisiones tácticas: *"¿Juego el minijuego gratis o gasto dinero para atenderlos a todos más rápido?"*

## 9. CAPACIDAD DE MASCOTAS

Actualmente controlada de facto por `player.capacity` y revisada al hacer spawn.
**Fórmula de progresión propuesta:**
El paso de 4 a 5 requerirá la compra del ítem estático `upgrade_capacity_1`. Al procesar esta compra, `player.capacity++`.
La comprobación de la tienda filtrará la visibilidad de los upgrades en base a si la capacidad actual del jugador es menor a la que proporciona el upgrade.

## 10. VALIDACIÓN Y SEGURIDAD

**En el Cliente:**
Prevención de bugs lógicos: Comprobar fondos suficientes, imposibilidad de comprar cantidades negativas, bloqueo del botón de compra temporalmente (debouncing) para evitar dobles clics.

**En el Backend (El reto del Local-First):**
Puesto que el cliente envía su propio estado completo, el jugador malintencionado podría enviar un `GameSave` inyectado con `coins = 999999`.
*Solución Anti-Cheat por Validación de Deltas:*
Dentro de `GameSaveService.syncSave` en Spring Boot, el servidor debe recuperar el `currentSave` de MongoDB y compararlo con el `incomingSave`:
1. Si `incomingSave.coins > currentSave.coins`: Solo es legal si `incomingSave.completedStays.size > currentSave.completedStays.size`.
2. Si `incomingSave.coins < currentSave.coins`: La diferencia debe corresponder al valor matemático de un ítem añadido al `Inventory` o al aumento de un `Upgrade`.
Si la delta no cuadra con el catálogo de precios, el backend rechaza con `CONFLICT` o `FORBIDDEN` y devuelve el estado correcto de la DB, forzando al cliente infractor a sobreescribir su progreso corrupto.

## 11. TESTS NECESARIOS

Antes de conectar UI, desarrollaremos:
* `EconomyTest`: Comprar con saldo suficiente resta monedas y añade inventario.
* `EconomyTest`: Excepción si no hay saldo suficiente.
* `InventoryTest`: Consumir objeto reduce la cantidad en el mapa; desaparece si llega a 0.
* `ValidationTest`: Intentar comprar cantidades inválidas o nulas.
* `UpgradeTest`: Aumentar capacidad correctamente mediante tienda.

## 12. DISEÑO Y UI

* **HUD:** Añadir un indicador superior persistente (`CoinCounterWidget`) visible en `NurseryScreen`.
* **Tienda:** Integrar un botón persistente (ícono de carrito) que levante un Modal Bottom Sheet o empuje la ruta a `ShopScreen`.
* **Inventario:** Modal al seleccionar una mascota activa en la guardería, permitiendo elegir una opción "Dar Objeto" junto al botón de "Acciones (Minijuegos)".

## 13. ROADMAP DE IMPLEMENTACIÓN TÉCNICA

* **FASE 3.1: Modelado Core (Dart)** - Añadir mapa de inventario al `Player`. Crear catálogo estático `StoreCatalog`. Lógica `addCoins`, `deductCoins`.
* **FASE 3.2: Lógica de Compras y Tests (Dart)** - Implementar `buyItem` y `consumeItem` en `GameState`. Escribir su batería de tests puros.
* **FASE 3.3: UI Base (Flutter)** - Widget de Monedas en HUD y actualización de los placeholders `ShopScreen` y `InventoryScreen`.
* **FASE 3.4: Sistema Consumibles (Flutter)** - Flujo UI para aplicar el objeto a la mascota e integración visual en la Guardería.
* **FASE 3.5: Mejoras Permanentes (Flutter)** - Compra de capacidad y refresco automático de la lógica de Spawns.
* **FASE 3.6: Seguridad de Sincronización (Backend)** - Integrar la validación por *Deltas* en el `GameSaveService` de Spring Boot.
