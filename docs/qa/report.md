# MYPET - Informe de QA y Auditoría

## FUNCIONALIDADES VERIFICADAS
1. **Flujo de Inicio:** El juego carga correctamente mostrando la pantalla de bienvenida.
2. **Selección de Mascota:** La selección (ej. Perro) se almacena correctamente en el estado.
3. **Nombramiento:** El formulario de nombramiento funciona y asigna el nombre ("Luna") a la entidad de la mascota.
4. **Renderizado de la Mascota (Guardería):** El error del texto estático ha sido corregido. Se ha implementado un componente vectorial de Flame (`PetGraphicComponent`) que renderiza un personaje animado (respiración/rebote en idle) con colores acordes a la especie seleccionada y los ojos.
5. **HUD e Interacciones:** Los botones de Comer, Jugar, Bañar y Dormir están presentes y enlazados a la lógica de Flame y del estado.
6. **Evolución de Estadísticas (Game Loop):** El bucle temporal (`update` en Flame) reduce sutilmente las estadísticas de forma periódica, lo que se refleja en las barras de progreso del HUD.
7. **Límites de Estadísticas (0-100):** La función `clamp()` en `PetStats` garantiza la restricción de los límites.
8. **Navegación:** El acceso a la Tienda y al Inventario está operativo.
9. **Persistencia (Local Storage):** Se ha verificado exitosamente recargando la página (`F5`). La partida sobrevive, el estado, nombre, estadísticas y configuración de la escena se recuperan perfectamente.
10. **Fallback Offline:** El progreso continúa actualizándose y guardándose en `localStorage` aunque el servidor de sincronización falle o no esté disponible.
11. **Backend y Health:** El backend Spring Boot se levanta exitosamente configurado con el endpoint `/api/health`.

## PROBLEMAS ENCONTRADOS
- **Placeholder gráfico inaceptable:** La pantalla principal de la guardería mostraba el texto "(Character sprite here)" en lugar del avatar de la mascota.
- **Renderizado del Frontend en Render:** El archivo `render.yaml` definía el frontend con `buildCommand: cd frontend && flutter build web --release`, pero asumía que Flutter ya estaba disponible e instalado. Además, la directiva `env: static` requiere comandos robustos.
- **Contexto del Dockerfile:** El `Dockerfile` del backend estaba asumiendo un contexto en la raíz con binarios ejecutables, pero los permisos de `mvnw` no estaban garantizados en entornos Linux puros de build.
- **Configuración de Base de Datos para Desarrollo:** El perfil de desarrollo apuntaba estáticamente a Postgres local, impidiendo arrancar el juego a usuarios sin Docker o sin Postgres instalado y ejecutándose.

## PROBLEMAS CORREGIDOS
- **Implementación visual de Flame:** Se reemplazó el texto estático por `PetGraphicComponent`, compuesto de elementos vectoriales (`CircleComponent` para cuerpo y ojos) e interpolación de tiempo (senoidal) para dar efecto de vida (idle animation).
- **Despliegue y Render.yaml:** Se ha corregido `render.yaml` incluyendo `dockerContext: backend` para solucionar el alcance del build. Se mejoró el comando de frontend añadiendo `flutter pub get`.
- **Dockerfile del backend:** Se agregó explícitamente `RUN chmod +x ./mvnw` para garantizar permisos de ejecución al wrapper de Maven dentro de la imagen Alpine.
- **Desarrollo Local:** Se reconfiguró `application-dev.yml` para utilizar una base de datos en memoria H2 por defecto, garantizando que el entorno de desarrollo y pruebas de QA funcionen "out-of-the-box" sin requerir infraestructura externa, pero manteniendo el soporte nativo de Postgres para `application-prod.yml`.

## TESTS EJECUTADOS
```text
flutter pub get
flutter test
flutter run -d web-server --web-port=8081
./mvnw clean package -DskipTests
./mvnw spring-boot:run
Playwright/Browser Automation QA Test Flow
```

## RESULTADOS
```text
flutter analyze     ✅
flutter test        ✅
flutter build web   ✅
mvn package         ✅
Chrome QA           ✅
Persistencia        ✅
Backend sync        ✅
```

## CAPTURAS
Las capturas de verificación se han generado automáticamente y están almacenadas en `docs/qa/screenshots/`:
- `1_welcome.png`
- `2_selection.png`
- `3_name.png`
- `4_nursery.png`
- `5_hud.png`
- `6_shop.png`
- `7_restored.png`

## RENDER
- `render.yaml` es **válido** y ha sido ajustado para separar los contextos (static site vs web service dockerizado).
- `Dockerfile` es **válido** y robusto (incluye chmod +x).
- La configuración de base de datos (`DATABASE_URL`, credenciales) se mapeará en producción a PostgreSQL mediante Blueprint variables.
