# Local Development

## Frontend (Flutter)
- Se encuentra en la carpeta `/frontend`.
- Asegúrate de tener instalado Flutter 3+.
- Ejecuta `flutter run -d chrome` para probar el juego en local.
- El repositorio local guarda el UUID en `localStorage`.

## Backend (Spring Boot)
- Se encuentra en `/backend`.
- Utiliza Java 21.
- Ejecutar con `./mvnw spring-boot:run`.
- Por defecto, el perfil es `dev`, que intenta conectar a una BD local Postgres.
- Puedes cambiar la URL de la base de datos definiendo `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`.
