# Guía Completa de Deployment - Sistema de Inventario GCP

Esta guía te llevará paso a paso desde cero hasta tener tu aplicación corriendo en producción.

## 📋 Pre-requisitos Checklist

Antes de comenzar, asegúrate de tener:

- [ ] Cuenta de Google Cloud Platform
- [ ] Tarjeta de crédito válida en GCP (para facturación)
- [ ] gcloud CLI instalado
- [ ] Terraform instalado (>= 1.0)
- [ ] Docker instalado
- [ ] Git instalado
- [ ] Acceso a este repositorio

## 🎯 Parte 1: Configuración de GCP (15 minutos)

### 1.1. Crear Proyecto en GCP

1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Click en el selector de proyectos (arriba a la izquierda)
3. Click en "New Project"
4. Nombre: `inventory-system-prod` (o el que prefieras)
5. Click "Create"
6. **Anota el Project ID** (lo necesitarás después)

### 1.2. Habilitar Facturación

1. En el menú lateral → "Billing"
2. Link a una cuenta de facturación
3. Si no tienes una, crea una nueva
4. Asocia el proyecto a la cuenta de facturación

### 1.3. Instalar y Configurar gcloud CLI

```bash
# Verificar instalación
gcloud version

# Autenticarse
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Configurar región por defecto
gcloud config set compute/region us-central1

# Autenticación para aplicaciones
gcloud auth application-default login
```

### 1.4. Verificar Configuración

```bash
# Ver configuración actual
gcloud config list

# Debería mostrar:
# [core]
# project = your-project-id
# [compute]
# region = us-central1
```

## 🏗️ Parte 2: Preparar el Código (10 minutos)

### 2.1. Clonar Repositorio

```bash
# Si ya tienes el código localmente, salta este paso
git clone git@github.com:rodrigoacd/inventory-system-gcp.git
cd inventory-system-gcp
```

### 2.2. Configurar Variables de Terraform

```bash
cd terraform

# Copiar template
cp terraform.tfvars.example terraform.tfvars

# Editar archivo
nano terraform.tfvars
```

**Reemplazar estos valores**:

```hcl
project_id        = "inventory-system-prod"          # TU PROJECT ID
region            = "us-central1"                    # Tu región preferida
service_name      = "inventory-system"               # Nombre del servicio
bucket_name       = "inventory-system-prod-images"   # DEBE SER ÚNICO GLOBALMENTE
database_name     = "inventory"                      # Nombre de la BD
database_user     = "inventory_user"                 # Usuario de BD
database_password = "Mi$uper$ecret0P@ssw0rd2024!"   # PASSWORD FUERTE
cloud_run_image   = "gcr.io/inventory-system-prod/inventory-app:latest"  # Imagen Docker
```

**⚠️ IMPORTANTE - Generador de Password Seguro**:

```bash
# Generar password fuerte (Linux/Mac)
openssl rand -base64 24
```

### 2.3. Guardar Configuración de Forma Segura

```bash
# NUNCA subir terraform.tfvars a Git
echo "terraform.tfvars" >> .gitignore

# Para backup seguro, usa git-crypt o similar
```

## 🐳 Parte 3: Build y Deploy de Aplicación (20 minutos)

### 3.1. Build de Imagen Docker con Cloud Build

```bash
# Navegar a directorio de app
cd ../app

# Verificar que Dockerfile existe
ls -la Dockerfile

# Build y push usando Cloud Build (RECOMENDADO)
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/inventory-app:latest .

# Esto tomará 3-5 minutos
```

**Salida esperada**:
```
Creating temporary tarball archive...
Uploading tarball...
...
DONE
ID: abc123...
CREATE_TIME: 2024-01-15T10:30:00+00:00
DURATION: 2m45s
SOURCE: ...
IMAGES: gcr.io/YOUR_PROJECT_ID/inventory-app:latest
STATUS: SUCCESS
```

### 3.2. Verificar Imagen en Container Registry

```bash
# Listar imágenes
gcloud container images list

# Ver tags de la imagen
gcloud container images list-tags gcr.io/YOUR_PROJECT_ID/inventory-app
```

### 3.3. (Alternativa) Build Local y Push

Si prefieres build local:

```bash
# Build local
docker build -t gcr.io/YOUR_PROJECT_ID/inventory-app:latest .

# Configurar Docker para usar gcloud
gcloud auth configure-docker

# Push a Container Registry
docker push gcr.io/YOUR_PROJECT_ID/inventory-app:latest
```

## ☁️ Parte 4: Desplegar Infraestructura con Terraform (30 minutos)

### 4.1. Inicializar Terraform

```bash
cd ../terraform

# Inicializar (descarga providers)
terraform init
```

**Salida esperada**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 5.0"...
- Installing hashicorp/google v5.x.x...
Terraform has been successfully initialized!
```

### 4.2. Validar Configuración

```bash
# Validar sintaxis de archivos .tf
terraform validate

# Debería retornar: Success! The configuration is valid.
```

### 4.3. Preview de Cambios

```bash
# Ver qué recursos se crearán
terraform plan

# Revisar cuidadosamente el plan
# Deberías ver:
# - google_compute_network
# - google_compute_subnetwork
# - google_sql_database_instance
# - google_storage_bucket
# - google_cloud_run_service
# etc.
```

### 4.4. Aplicar Infraestructura

```bash
# Aplicar cambios
terraform apply

# Terraform te pedirá confirmación
# Escribe: yes
```

**⏱️ Este proceso tomará 10-15 minutos**

Durante este tiempo, Terraform:
1. Habilita APIs necesarias (2 min)
2. Crea VPC y networking (2 min)
3. Crea Cloud Storage bucket (30 seg)
4. Crea Cloud SQL instance (8-10 min) ← La parte más lenta
5. Despliega Cloud Run service (1 min)

**Salida esperada**:
```
...
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "inventory-system-prod-images"
bucket_url = "gs://inventory-system-prod-images"
cloud_run_url = "https://inventory-system-abc123-uc.a.run.app"
cloud_sql_connection_name = "inventory-system-prod:us-central1:inventory-db-abc123"
cloud_sql_instance_ip = "34.123.456.78"
```

### 4.5. Guardar Outputs

```bash
# Guardar URL de la aplicación
export APP_URL=$(terraform output -raw cloud_run_url)
echo $APP_URL

# Probar que responde
curl $APP_URL/health
```

## ✅ Parte 5: Verificación y Testing (10 minutos)

### 5.1. Verificar Servicios

```bash
# Cloud Run
gcloud run services list
gcloud run services describe inventory-system --region=us-central1

# Cloud SQL
gcloud sql instances list
gcloud sql instances describe $(terraform output -raw cloud_sql_connection_name | cut -d: -f3)

# Cloud Storage
gcloud storage buckets list
gcloud storage ls gs://$(terraform output -raw bucket_name)/
```

### 5.2. Testing de Aplicación

```bash
# Health check
curl $APP_URL/health

# Debería retornar:
# {"status":"healthy","database":"connected"}

# Abrir en navegador
open $APP_URL  # macOS
xdg-open $APP_URL  # Linux
```

### 5.3. Probar funcionalidad

En el navegador:
1. ✅ Debería ver la página principal vacía
2. ✅ Click en "Agregar Producto"
3. ✅ Llenar formulario con datos de prueba
4. ✅ Subir una imagen
5. ✅ Guardar
6. ✅ Verificar que aparece en la lista

### 5.4. Ejecutar Tests

```bash
# Tests de Python
cd terraform/tests
python3 test_terraform_config.py

# Resultado esperado:
# Ran 10 tests
# OK (expected failures=2)
```

## 🔍 Parte 6: Monitoreo y Logs (5 minutos)

### 6.1. Ver Logs de Cloud Run

```bash
# Logs recientes
gcloud run services logs read inventory-system \
  --region=us-central1 \
  --limit=50

# Seguir logs en tiempo real
gcloud run services logs tail inventory-system \
  --region=us-central1
```

### 6.2. Dashboard de GCP

1. Ve a [Cloud Console](https://console.cloud.google.com)
2. Cloud Run → inventory-system
3. Tab "Logs" para ver logs
4. Tab "Metrics" para ver métricas

### 6.3. Configurar Alertas (Opcional)

```bash
# Crear alerta por errores
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Inventory System Errors" \
  --condition-display-name="Error rate" \
  --condition-threshold-value=10 \
  --condition-threshold-duration=60s
```

## 🎉 ¡Deployment Completado!

Tu aplicación ahora está corriendo en:
- 🌐 URL: `$APP_URL`
- 🗄️ Base de datos: Cloud SQL MySQL
- 📦 Imágenes: Cloud Storage
- 🚀 Hosting: Cloud Run

## 📝 Próximos Pasos

1. **Configurar dominio personalizado**
   ```bash
   gcloud run domain-mappings create \
     --service=inventory-system \
     --domain=inventory.tudominio.com \
     --region=us-central1
   ```

2. **Configurar CI/CD con Cloud Build**
   - Crear `cloudbuild.yaml`
   - Conectar con GitHub
   - Auto-deploy en cada push

3. **Implementar monitoreo avanzado**
   - Configurar Uptime checks
   - Crear dashboards personalizados
   - Alertas por email/SMS

4. **Optimizar costos**
   - Revisar métricas de uso
   - Ajustar recursos según necesidad
   - Implementar lifecycle policies

## 🆘 Troubleshooting

### Error: "Permission denied"

**Problema**: Tu cuenta no tiene permisos suficientes

**Solución**:
```bash
# Agregar roles necesarios
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:your-email@gmail.com" \
  --role="roles/owner"
```

### Error: "Quota exceeded"

**Problema**: Has excedido cuotas de GCP

**Solución**:
1. Ve a IAM & Admin → Quotas
2. Busca el recurso con problema
3. Request quota increase

### Error: "Cloud SQL connection failed"

**Problema**: Cloud Run no puede conectar a Cloud SQL

**Solución**:
```bash
# Verificar que service networking está correcto
gcloud services vpc-peerings list --network=inventory-vpc

# Verificar que Cloud SQL tiene IP privada
gcloud sql instances describe INSTANCE_NAME --format="get(ipAddresses)"
```

### Aplicación no carga

**Checklist de debugging**:

```bash
# 1. Verificar que Cloud Run está corriendo
gcloud run services describe inventory-system --region=us-central1

# 2. Ver logs recientes
gcloud run services logs read inventory-system --region=us-central1 --limit=100

# 3. Verificar variables de entorno
gcloud run services describe inventory-system \
  --region=us-central1 \
  --format="get(spec.template.spec.containers[0].env)"

# 4. Probar health endpoint
curl $APP_URL/health -v
```

## 🧹 Limpieza (Si quieres eliminar todo)

```bash
cd terraform

# Ver qué se eliminará
terraform plan -destroy

# Eliminar todos los recursos
terraform destroy

# Confirmar con: yes
```

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs: `gcloud run services logs read inventory-system`
2. Verifica la documentación: [README.md](README.md)
3. Revisa issues en GitHub

---

**¡Felicitaciones! 🎉 Tu sistema de inventario está en producción.**
