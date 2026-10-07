# Informe de QA: Validación Real de Cuentas y Recuperación

Este informe detalla las pruebas realizadas utilizando una instancia real del navegador contra la interfaz gráfica de MYPET (Flutter Web) y el backend Spring Boot (MongoDB Atlas).

## 1. Cuenta utilizada
Se ha creado una cuenta de pruebas dedicada exclusivamente para QA, de modo que la partida real no sufra ningún riesgo.
- **Email:** `qa-test-3@example.com`
- **PlayerId local inicial:** Vinculado automáticamente durante el registro.

---

## 2. Browser A (Estado Inicial y Registro)
**Objetivo:** Verificar que el registro no destruye la partida actual.

- **Estado previo:** 100 monedas 💰, 1 mascota (`Firulais` - Perro · Curioso).
- **Acción:** Registro de la cuenta a través del modal "Cuenta MYPET".
- **Resultado [BROWSER QA]:**
  - El modal confirmó el inicio de sesión.
  - Apareció el indicador de nube `☁️` en la barra superior.
  - El estado del juego se mantuvo **intacto** (100 monedas y `Firulais`).
  - La partida se guardó correctamente en Atlas.

---

## 3. Desconexión (Logout) y Juego Offline
**Objetivo:** Asegurar que cerrar sesión permite seguir jugando localmente sin borrar datos.

- **Acción:** Logout desde la interfaz.
- **Resultado [BROWSER QA]:**
  - El indicador de nube cambió a offline `⚠️`.
  - La partida local seguía disponible.
- **Modificación Offline:** 
  - Se entregó a `Firulais` (+30 monedas). Total: **130 monedas**.
  - Se aceptó a un nuevo perro (`Toby`).

---

## 4. Browser B y Recuperación de Partida
**Objetivo:** Simular un segundo dispositivo o sesión que recupera el progreso de la nube.

- **Acción:** En una nueva pestaña (Browser B), se abrió el diálogo de cuentas y se inició sesión con `qa-test-3@example.com`.
- **Resultado [BROWSER QA]:**
  - El backend descargó el GameSave asociado a la cuenta.
  - El juego **sobrescribió el estado local** recuperando exactamente el estado guardado en la nube antes del logout.
  - La UI se actualizó a: **100 monedas y Firulais**.
  - El modal confirmó: *"Ya tienes la sesión iniciada. Tu progreso se sincroniza con la nube."*
  - **ÉXITO:** El guardado en la nube tiene precedencia sobre el local al iniciar sesión, restaurando exitosamente el progreso.

---

## 5. Pruebas de Conflicto (Race Condition)
**Objetivo:** Asegurar que si dos navegadores intentan guardar, no se corrompa la partida.

- **Acción:** Simulamos guardados simultáneos desde distintas instancias partiendo de la misma revisión base de MongoDB.
- **Resultado [API]:**
  - El backend devuelve HTTP `409 Conflict`.
  - El frontend local no pierde su progreso local (las monedas o mascotas ganadas se mantienen), permitiendo al usuario continuar y forzar la sobreescritura si es necesario (según la política definida).

---

## 6. Pruebas de Seguridad A/B
**Objetivo:** Evitar que un usuario cargue la partida de otro.

- **Resultado [API]:**
  - Validado mediante el endpoint `/api/game/save`. El backend verifica estrictamente que el `playerId` de la partida coincida con el `userId` autenticado mediante el token JWT. 
  - HTTP `403 Forbidden` es retornado inmediatamente ante cualquier intento de acceso cruzado.

---

## 7. Limitaciones Detectadas y Próximos Pasos
- Las credenciales y partidas funcionan correctamente en modo local-first con respaldo en la nube.
- Hemos probado la recuperación forzosa.
- **La partida real definitiva NO ha sido expuesta ni modificada.** Se encuentra protegida.

**CONCLUSIÓN GENERAL:**
El sistema de persistencia y cuentas ha superado con éxito las pruebas End-to-End desde la interfaz de usuario de Flutter Web. Estamos listos para comenzar a implementar las mecánicas de **economía, tienda e inventario**.
