# Arquitectura de MYPET

```text
                    INTERNET
                       │
                       ▼
             ┌──────────────────────┐
             │       RENDER         │
             │                      │
             │    Flutter Web       │
             │     Static Site      │
             └──────────┬───────────┘
                        │
                     HTTPS
                        │
                        ▼
             ┌──────────────────────┐
             │       RENDER         │
             │                      │
             │     Spring Boot      │
             │     Web Service      │
             └──────────┬───────────┘
                        │
                        ▼
             ┌──────────────────────┐
             │       RENDER         │
             │                      │
             │      PostgreSQL      │
             └──────────────────────┘
```

- El frontend usa localStorage para guardar la partida.
- El juego puede funcionar 100% offline (sin backend) y no se perderán datos.
- Cuando hay backend, se envía una petición POST /api/game/sync para replicar el progreso en PostgreSQL.
- Flame Engine se usa en Flutter para manejar el bucle del juego (`update()`) y los elementos gráficos de la guardería.
