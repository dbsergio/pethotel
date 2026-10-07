# Informe de QA: Indicador de Sincronización y Backend Render

Este informe documenta las soluciones implementadas en el cliente y la auditoría pre-despliegue del backend en Render hacia MongoDB Atlas.

## 1. Indicador de Sincronización

### Problema Encontrado
Anteriormente, el indicador visual de estado en `NurseryScreen` dependía únicamente del valor interno `SyncStatus` del `GameSyncService`. Si el usuario no estaba logueado y realizaba una acción, el guardado local se marcaba como `pending`. Al intentar sincronizar sin credenciales, el servicio fallaba (network error por falta de auth) o se quedaba en estado `error`/`pending`, lo que provocaba que la UI mostrara un molesto `⚠️ Pendiente de sincronizar` de forma permanente, dando a entender a los jugadores en modo local que algo iba mal con su partida.

### Solución
Se modificó `_SyncIndicator` en `nursery_screen.dart` para que evalúe primero el estado de autenticación (`AuthRepository().isLoggedIn()`). 

Los estados ahora son deterministas y precisos:
- **Sin cuenta (local-first)**: Muestra `☁ Solo local`. Ya no se considera un error.
- **Logueado (guardado)**: Muestra `☁ Guardado`.
- **Logueado (guardando)**: Muestra `☁ Sincronizando...`.
- **Logueado (cambios locales)**: Muestra `⚠️ Pendiente de sincronizar`.
- **Logueado (sin internet)**: Muestra `⚠️ Sin conexión`.
- **Conflicto detectado**: Muestra `⚠️ Conflicto de sincronización`.

---

## 2. Configuración Render

El backend ya está completamente preparado para desplegarse como un **Web Service Docker** en Render.

El archivo `render.yaml` (Infrastructure as Code) ha sido actualizado para reflejar la conexión a MongoDB Atlas.

### Pasos Manuales a Realizar en Render:

1. Ve al Dashboard de Render y asegúrate de sincronizar o redesplegar el servicio Web llamado `mypet-backend` (que utiliza Docker).
2. En la pestaña **Environment** del servicio, debes configurar las siguientes variables de entorno:
   - `SPRING_PROFILES_ACTIVE` = `prod` *(ya configurado en render.yaml)*
   - `MONGODB_DATABASE` = `mypethotel` *(ya configurado en render.yaml)*
   - `MONGODB_URI` = `mongodb+srv://<TU_USUARIO>:<TU_PASSWORD>@mypethotel.ohz8ya5.mongodb.net/mypet?retryWrites=true&w=majority&appName=MyPetHotel`
   - `JWT_SECRET` = `<TU_SECRETO>` (Cualquier string largo y seguro).

### URL Pública del Backend
Render te asignará automáticamente una URL, por ejemplo: `https://mypet-backend.onrender.com`. Esta URL será la que utilicemos en Flutter en la siguiente fase.

---

## 3. Health Check

Se ha configurado y validado el endpoint `/api/health`.
- Render utilizará esta ruta para determinar si el contenedor ha arrancado correctamente.
- Retorna un simple `OK` (HTTP 200) sin realizar consultas pesadas a la base de datos, garantizando arranques rápidos.

---

## 4. MongoDB Atlas

### Conexión
La aplicación en perfil `prod` utiliza la variable de entorno `${MONGODB_URI}`.
El bean personalizado `MongoConfig` asegura que la aplicación se conecte exclusivamente a Atlas, anulando cualquier fallback automático de Spring Boot a `localhost:27017`.

### Network Access
**IMPORTANTE:** Si Atlas bloquea las IPs de Render, deberás ir a MongoDB Atlas -> Network Access y añadir la IP `0.0.0.0/0` (Allow Access from Anywhere) temporalmente o añadir las IPs estáticas de Render (si tienes plan de pago en Render).

---

## 5. Pruebas Automáticas (API)

Se han ejecutado scripts locales en PowerShell (simulando las peticiones que haría Render/Frontend) contra el archivo `.jar` compilado localmente con perfil `prod`.

| Endpoint | Resultado | Detalle |
| :--- | :--- | :--- |
| `GET /api/health` | ✅ OK | El servicio responde correctamente. |
| `POST /api/auth/register` | ✅ 200 OK | Retorna token JWT correctamente con usuario de QA. |
| `POST /api/auth/login` | ✅ 200 OK | Validación de JWT exitosa. |
| `POST /api/game/save` | ✅ 200 OK | Persistencia correcta en MongoDB Atlas utilizando el token. |
| `GET /api/game/save/{id}` | ✅ 200 OK | Recuperación completa del estado JSON (coins, etc). |
| *Seguridad de Usuario* | ✅ 403 Forbidden | Acceso cruzado prevenido verificando que el `playerId` de la URL o Body coincida con el `sub` del token JWT. |

---

## 6. Limitaciones Actuales y Próximos Pasos

- **CORS:** El backend en producción actualmente acepta orígenes con `*`. Esto es adecuado para la fase en la que estamos (pruebas de Render URL desde localhost Flutter), pero deberá restringirse una vez publiquemos el Frontend Static Site de Render.
- **Frontend:** El frontend todavía no apunta a la URL en la nube (sigue en local). Modificaremos esto cuando me confirmes la URL pública generada por Render.

**CONCLUSIÓN:**
El backend está verificado y listo. No se han tocado las partidas reales de tu amiga. 
Puedes proceder a desplegarlo y comunicarme los resultados.
