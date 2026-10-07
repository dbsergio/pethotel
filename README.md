# MYPET

MYPET es un videojuego web de mascotas virtuales. Recupera la sensación de los antiguos juegos de cuidar mascotas de Nintendo DS y juegos similares de los años 2000, pero con identidad propia, diseño moderno en 2D cartoon y una experiencia relajante.

## Arquitectura

El proyecto se divide en dos componentes principales:

1. **Frontend**: Desarrollado en **Flutter** y **Flame** para Flutter Web.
2. **Backend**: Desarrollado en **Spring Boot** (Java 21) conectado a una base de datos **PostgreSQL**.

## Requisitos

- Flutter SDK
- Dart SDK
- Java 21 (o compatible)
- Maven
- PostgreSQL
- Docker (opcional, para backend local)

## Instalación y Ejecución

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Backend (Spring Boot)

Antes de iniciar el backend, configura una base de datos PostgreSQL y establece las variables de entorno en `application-dev.yml` o a través del sistema.

```bash
cd backend
./mvnw clean package
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

O usando Docker:

```bash
cd backend
docker build -t mypet-backend .
docker run -p 8080:8080 mypet-backend
```

## Estructura del Proyecto

- `frontend/`: Código fuente del juego en Flutter.
- `backend/`: Código fuente del Web Service en Spring Boot.
- `render.yaml`: Configuración para despliegue automático en Render.
- `docs/`: Documentación adicional.

## Despliegue en Render

El proyecto incluye un archivo `render.yaml` (Blueprint) para un despliegue sin esfuerzo.

1. Conecta este repositorio en tu cuenta de [Render](https://render.com).
2. Render detectará automáticamente el Blueprint y creará:
   - Una base de datos PostgreSQL (Free Tier).
   - Un Web Service para el backend Spring Boot.
   - Un Static Site para compilar y servir el frontend de Flutter.

## UptimeRobot (Mantener el backend despierto)

Render duerme los Web Services del plan gratuito después de 15 minutos de inactividad.
Para evitarlo y garantizar que las sincronizaciones no fallen, configura **UptimeRobot**:

1. Ve a [UptimeRobot](https://uptimerobot.com).
2. Crea un nuevo monitor de tipo **HTTP(s)**.
3. Apunta a la URL de tu backend añadiendo el endpoint `/api/health`.
   - Ejemplo: `https://mypet-backend.onrender.com/api/health`
4. Configura el intervalo a 5-10 minutos.

Esto asegurará que tu servidor Spring Boot esté siempre listo para sincronizar la partida.
