# API Backend

## GET /api/health
Retorna el estado de salud del servicio (para UptimeRobot).
Respuesta: `{"status": "UP", "service": "mypet-backend", "version": "1.0.0"}`

## POST /api/game/sync
Sincroniza el estado local del jugador con la base de datos PostgreSQL.
Si el jugador no existe, lo crea. Si existe, actualiza las monedas y el estado completo de la mascota (estadísticas actuales).

Body esperado:
```json
{
  "player": {
    "id": "UUID",
    "coins": 100
  },
  "currentPet": {
    "id": "UUID",
    "name": "Fido",
    "species": "dog",
    "stats": {
      "hunger": 100.0,
      "thirst": 100.0,
      "hygiene": 100.0,
      "energy": 100.0,
      "happiness": 100.0
    }
  }
}
```
