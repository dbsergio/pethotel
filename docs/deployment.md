# Despliegue en Render

El proyecto está configurado para un despliegue "Zero-Downtime" gratuito en Render usando `render.yaml`.

## Servicios configurados en render.yaml:
1. **mypet-db**: Instancia PostgreSQL.
2. **mypet-backend**: Spring Boot. Construido mediante Docker. Las credenciales de BD se enlazan automáticamente.
3. **mypet-frontend**: Sitio estático. Construye el flutter web y lo sirve desde `build/web`.

Para desplegar:
- Sube esto a GitHub.
- Ve a Render.com -> Blueprints -> New Blueprint Instance -> Conecta tu repo.
- ¡Listo! Todo se desplegará.
