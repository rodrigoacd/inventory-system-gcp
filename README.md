# Sistema de Inventario - GCP con Terraform

Sistema completo de gestión de inventario desplegado en Google Cloud Platform usando Infrastructure as Code (Terraform).

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Prerequisitos](#prerequisitos)
- [Configuración Inicial](#configuración-inicial)
- [Deployment Manual](#deployment-manual)
- [Testing](#testing)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Costos Estimados](#costos-estimados)

## 🎯 Descripción

Sistema web de inventario para pequeños negocios que incluye:

- ✅ Gestión completa de productos (CRUD)
- ✅ Control de stock (entradas/salidas)
- ✅ Almacenamiento de imágenes en Cloud Storage
- ✅ Base de datos MySQL en Cloud SQL
- ✅ Dashboard con estadísticas en tiempo real
- ✅ API REST para integraciones
- ✅ Historial de transacciones

## 🏗️ Arquitectura

```
┌─────────────────┐
│   Cloud Run     │ ← Aplicación Flask
│   (Container)   │
└────────┬────────┘
         │
         ├─────────────┐
         │             │
    ┌────▼─────┐  ┌───▼────────┐
    │ Cloud SQL│  │   Cloud    │
    │  (MySQL) │  │  Storage   │
    └──────────┘  └────────────┘
         │
    ┌────▼─────┐
    │   VPC    │
    │ Network  │
    └──────────┘
```

### Componentes:

1. **Cloud Run**: Aplicación web containerizada (Flask)
2. **Cloud SQL (MySQL)**: Base de datos relacional
3. **Cloud Storage**: Almacenamiento de imágenes de productos
4. **VPC Networking**: Red privada para seguridad

## 📦 Prerequisitos

### Software Requerido:

```bash
# 1. Google Cloud SDK
# macOS:
brew install google-cloud-sdk

# Linux:
curl https://sdk.cloud.google.com | bash

# 2. Terraform (>= 1.0)
# macOS:
brew install terraform

# Linux:
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# 3. Docker
# macOS:
brew install docker

# Linux:
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 4. Python 3.11+
python3 --version
```

### Cuenta de GCP:

- ✅ Cuenta de Google Cloud Platform
- ✅ Proyecto de GCP creado
- ✅ Facturación habilitada
- ✅ APIs necesarias habilitadas (el Terraform las habilita automáticamente)

## ⚙️ Configuración Inicial

### 1. Configurar Google Cloud SDK

```bash
# Autenticarse en GCP
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Autenticación para aplicaciones
gcloud auth application-default login
```

### 2. Habilitar APIs manualmente (opcional - Terraform lo hace automáticamente)

```bash
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable vpcaccess.googleapis.com
```

### 3. Configurar variables de Terraform

```bash
cd terraform

# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

Contenido de `terraform.tfvars`:

```hcl
project_id        = "tu-proyecto-gcp-12345"
region            = "us-central1"
service_name      = "inventory-system"
bucket_name       = "tu-proyecto-gcp-12345-inventory-images"
database_name     = "inventory"
database_user     = "inventory_user"
database_password = "TuPasswordSeguro123!@#"
cloud_run_image   = "gcr.io/tu-proyecto-gcp-12345/inventory-app:latest"
```

**⚠️ IMPORTANTE**: 
- Usa un password fuerte para `database_password`
- El `bucket_name` debe ser único globalmente
- Cambia `tu-proyecto-gcp-12345` por tu ID de proyecto real

## 🚀 Deployment Manual

### Paso 1: Construir y Subir la Imagen Docker

```bash
# Navegar al directorio de la aplicación
cd app

# Construir y subir imagen usando Cloud Build
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/inventory-app:latest

# Alternativa: Build local y push
docker build -t gcr.io/YOUR_PROJECT_ID/inventory-app:latest .
docker push gcr.io/YOUR_PROJECT_ID/inventory-app:latest
```

### Paso 2: Inicializar Terraform

```bash
cd ../terraform

# Inicializar Terraform (descarga providers)
terraform init
```

### Paso 3: Validar Configuración

```bash
# Validar sintaxis
terraform validate

# Ver cambios que se aplicarán
terraform plan
```

### Paso 4: Aplicar Infraestructura

```bash
# Aplicar cambios (crear recursos)
terraform apply

# Confirmar con: yes
```

Este proceso tomará aproximadamente **10-15 minutos** y creará:
- ✅ VPC Network y Subnet
- ✅ Cloud SQL MySQL Instance
- ✅ Cloud Storage Bucket
- ✅ Cloud Run Service

### Paso 5: Obtener URL de la Aplicación

```bash
# Ver outputs
terraform output

# O específicamente la URL:
terraform output cloud_run_url
```

### Paso 6: Verificar Deployment

```bash
# Verificar que la aplicación responda
curl $(terraform output -raw cloud_run_url)/health

# Debería retornar: {"status":"healthy","database":"connected"}
```

## 🧪 Testing

### Tests de Python (Validación de configuración)

```bash
cd terraform/tests

# Ejecutar tests
python3 test_terraform_config.py

# Resultado esperado:
# 8 tests passed ✓
# 2 tests failed ✗ (intencionalmente)
```

### Tests de Go (Terratest - opcional)

Si tienes Go instalado:

```bash
cd terraform/tests

# Instalar dependencias
go mod download

# Ejecutar tests
go test -v
```

### Validación Manual

```bash
# 1. Verificar Cloud Run
gcloud run services list

# 2. Verificar Cloud SQL
gcloud sql instances list

# 3. Verificar Cloud Storage
gcloud storage buckets list
```

## 📂 Estructura del Proyecto

```
inventory-system-gcp/
├── app/                          # Aplicación Flask
│   ├── app.py                   # Código principal
│   ├── templates/               # Templates HTML
│   │   ├── base.html
│   │   ├── index.html
│   │   ├── add_product.html
│   │   └── product_detail.html
│   ├── static/                  # Archivos estáticos
│   │   ├── css/style.css
│   │   └── js/app.js
│   ├── Dockerfile               # Imagen de container
│   └── requirements.txt         # Dependencias Python
│
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Configuración principal
│   ├── variables.tf             # Variables de entrada
│   ├── outputs.tf               # Outputs de recursos
│   ├── terraform.tfvars.example # Template de configuración
│   │
│   ├── modules/                 # Módulos reutilizables
│   │   ├── cloud_run/          # Módulo Cloud Run
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── cloud_sql/          # Módulo Cloud SQL
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── cloud_storage/      # Módulo Storage
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── networking/         # Módulo VPC
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── tests/                   # Tests de infraestructura
│       ├── test_terraform_config.py
│       ├── terraform_test.go
│       └── go.mod
│
├── README.md                    # Este archivo
├── DEPLOYMENT_GUIDE.md          # Guía detallada de deployment
└── .gitignore
```

## 💰 Costos Estimados

### Costos mensuales aproximados (uso moderado):

| Servicio | Configuración | Costo Mensual |
|----------|--------------|---------------|
| Cloud Run | 1M requests/mes | $5 - $20 |
| Cloud SQL | db-f1-micro (0.6GB RAM) | $7 - $15 |
| Cloud Storage | 10GB storage + 1GB egress | $0.50 - $2 |
| VPC Networking | Standard | $0 - $5 |
| **TOTAL** | | **~$15 - $40/mes** |

### Optimización de costos:

1. **Cloud Run**: Solo pagas por uso real (escalado a 0)
2. **Cloud SQL**: Considera usar snapshots para dev/test
3. **Storage**: Implementa lifecycle policies (incluidas en branches)
4. **Monitoreo**: Usa el free tier de Google Cloud Monitoring

## 🔒 Seguridad

### Mejores prácticas implementadas:

- ✅ VPC privada para Cloud SQL
- ✅ IAM roles con principio de menor privilegio
- ✅ Secrets en variables de Terraform (nunca en código)
- ✅ HTTPS enforced en Cloud Run
- ✅ Backups automáticos de base de datos
- ✅ CORS configurado apropiadamente

### Para producción, considera:

- 🔐 Usar **Secret Manager** para passwords
- 🔐 Habilitar **Cloud Armor** para protección DDoS
- 🔐 Configurar **Cloud IAP** para autenticación
- 🔐 Habilitar **deletion_protection** en Cloud SQL
- 🔐 Implementar **Cloud Audit Logs**

## 🔄 Actualizaciones y Mantenimiento

### Actualizar la aplicación:

```bash
# 1. Hacer cambios en el código
cd app

# 2. Rebuild y push de imagen
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/inventory-app:v2

# 3. Actualizar Cloud Run (automático con Terraform)
cd ../terraform
terraform apply
```

### Hacer backup de base de datos:

```bash
# Backup manual
gcloud sql backups create \
  --instance=INSTANCE_NAME \
  --description="Manual backup"

# Restaurar desde backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=SOURCE_INSTANCE \
  --backup-id=BACKUP_ID
```

## 🐛 Troubleshooting

### Problema: "Error enabling APIs"

**Solución**: Habilitar APIs manualmente primero:
```bash
gcloud services enable run.googleapis.com sqladmin.googleapis.com storage.googleapis.com
```

### Problema: "Permission denied" en Cloud Build

**Solución**: Asegurar que tu cuenta tiene permisos:
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/cloudbuild.builds.editor"
```

### Problema: Cloud Run no puede conectar a Cloud SQL

**Solución**: Verificar que la VPC peering está correcta:
```bash
gcloud services vpc-peerings list \
  --network=inventory-vpc
```

### Problema: "Bucket name already exists"

**Solución**: Los nombres de bucket son globalmente únicos. Cambiar el nombre en `terraform.tfvars`:
```hcl
bucket_name = "tu-proyecto-UNIQUEID-inventory-images"
```

## 🧹 Destruir Infraestructura

Para eliminar todos los recursos creados:

```bash
cd terraform

# Ver qué se eliminará
terraform plan -destroy

# Eliminar recursos
terraform destroy

# Confirmar con: yes
```

**⚠️ ADVERTENCIA**: Esto eliminará:
- Toda la base de datos (incluyendo datos)
- Todas las imágenes en Cloud Storage
- El servicio Cloud Run
- La VPC network

## 📚 Recursos Adicionales

- [Documentación de Terraform GCP](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Documentación de Cloud Run](https://cloud.google.com/run/docs)
- [Documentación de Cloud SQL](https://cloud.google.com/sql/docs)
- [Guía de mejores prácticas de GCP](https://cloud.google.com/architecture/framework)

## 👤 Autor

Rodrigo ACD - Proyecto DevOps con Infrastructure as Code

## 📄 Licencia

MIT License
