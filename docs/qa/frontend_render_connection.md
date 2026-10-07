# Informe de QA: Conexión Frontend-Backend Render

Este documento detalla la auditoría y actualización del código de Flutter para preparar el frontend a utilizar un backend dinámico según el entorno de compilación (Local vs Producción).

## 1. Configuración Anterior
El código de los repositorios en el frontend (`AuthRepository`, `LocalGameRepository`, `RemoteGameRepository`) tenía la URL base inyectada de dos formas inconsistentes o repetidas a lo largo de las distintas clases:
- Uso de `const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080')` replicado en cada clase.
- Uso de rutas absolutas inyectadas directamente sin una URL Base compartida.

## 2. Configuración Nueva (Entornos Dinámicos)
Se ha centralizado la configuración en el archivo `lib/core/config/app_config.dart`.
Esta clase estática `AppConfig` abstrae la obtención de la `baseUrl`. 

- **Local:** Si no se pasa ningún argumento de compilación, el frontend se conectará por defecto al backend Spring Boot corriendo en la máquina de desarrollo: `http://localhost:8080`.
- **Producción:** Para desplegar o ejecutar la aplicación conectada a la nube, la compilación de Flutter (o la ejecución en navegador) recibe la URL como un parámetro de entorno a nivel de Dart, evitando así hardcodear la URL productiva en el código fuente:

```bash
# Desarrollo local (sigue funcionando exactamente igual)
flutter run -d chrome

# Entorno conectado a producción (Render)
flutter run -d chrome --dart-define=API_URL=https://mypet-backend-42s3.onrender.com

# Build final para Render
flutter build web --release --dart-define=API_URL=https://mypet-backend-42s3.onrender.com
```

## 3. URLs
- **Local URL:** `http://localhost:8080`
- **Producción URL:** `https://mypet-backend-42s3.onrender.com`

## 4. Tests Ejecutados

Se validaron las siguientes áreas técnicas de la aplicación (sin tocar la partida original ni usar subagentes):
1. **Health Check Público (`GET https://mypet-backend-42s3.onrender.com/api/health`)**: Respondió `OK` exitosamente tras el cold-boot de Render. 
2. **Flutter Analyze**: Finalizado limpiamente sin errores (solo advertencias cosméticas por la nueva sintaxis de Dart 3.x, como `withValues()`).
3. **Flutter Build Web**: Compiló correctamente el binario release con la inyección dinámica a través de `--dart-define`.

## 5. Limitaciones
CORS en el servidor de Spring Boot (Render) actualmente sigue estando configurado con asterisco `*`. Esto significa que permite la conexión de localhost y del frontend. Una vez desplegado definitivamente el Frontend, deberemos configurar una política estricta limitando el CORS solo al dominio `https://mypet-frontend-XXXX.onrender.com`.
