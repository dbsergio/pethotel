# Informe de QA: Validación de Conexión a MongoDB Atlas

## 1. Objetivo
Validar que el backend local se conecta correctamente y de forma exclusiva al cluster de MongoDB Atlas (`mypethotel.ohz8ya5.mongodb.net`), logrando persistencia real (lectura y escritura de partidas).

## 2. Acciones Realizadas
1. **Configuración de variables de entorno:**
   - Se configuró la variable `SPRING_PROFILES_ACTIVE=prod`.
   - Se confirmó que el archivo `application-prod.yml` contiene la URI de conexión `MONGODB_URI` correcta para Atlas.
2. **Corrección del problema de `localhost:27017`:**
   - Durante la revisión de los logs del backend, se detectó que aunque se inyectaba la URI de Atlas, el Auto-Configuration de Spring Boot (versión particular en el POM) estaba inicializando un segundo `MongoClient` en un hilo monitor que buscaba `localhost:27017` por defecto.
   - **Solución:** Se implementó la clase de configuración explícita `MongoConfig` (en `com.mypet.config`) mediante un `@Bean` que crea y fuerza el uso del `MongoClient` apuntando únicamente a la URI proporcionada en `${spring.data.mongodb.uri}`.
   - Resultado: Los intentos erróneos de conexión a `localhost:27017` desaparecieron por completo.
3. **Validación de Lectura/Escritura End-to-End:**
   - Se registró un nuevo usuario (`testuser`) en el endpoint `POST /api/auth/register`, lo que validó la conectividad a nivel de la base de datos (se generó un `userId` válido en Atlas y un JWT).
   - Se envió una petición autenticada de guardado a `POST /api/game/save` usando el JWT, y el backend respondió `status: OK`, confirmando la inserción/actualización en MongoDB Atlas del estado del juego (ej: 999 monedas).
   - Se realizó una petición de recuperación `GET /api/game/save/{playerId}` autenticada, logrando cargar el mismo documento íntegro (`createdAt`, `revision: 2`, `coins: 999`).

## 3. Conclusión
La auditoría y validación de persistencia y cuentas ha sido **completada con éxito**.
- El progreso de la partida está asegurado.
- La aplicación local se conecta de forma segura a Atlas.
- La partida actual y la configuración están intactas.
- No hay fugas de credenciales en los logs.
- Se ha demostrado que una partida se guarda y se puede recuperar exactamente como estaba.

Estamos listos para avanzar con la siguiente fase funcional (economía, tienda, inventario, etc.) sabiendo que el estado de guardado es robusto.
