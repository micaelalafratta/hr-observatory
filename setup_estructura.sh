#!/usr/bin/env bash
# setup_estructura.sh
# ---------------------------------------------------------
# Crea la estructura de carpetas de la Fase 1 del proyecto
# "Observatorio del Mercado Laboral de Datos y Gobernanza en España"
#
# Cómo usarlo:
#   1. Copia este archivo a la raíz de tu repo local (donde está la carpeta .git)
#   2. Dale permisos de ejecución:   chmod +x setup_estructura.sh
#   3. Ejecútalo:                    ./setup_estructura.sh
#
# Es idempotente: si vuelves a correrlo, no rompe nada que ya exista.
# ---------------------------------------------------------

set -e  # si algo falla, el script se detiene en vez de seguir a medias

echo "Creando estructura de carpetas..."

# --- Carpetas de datos ---
# raw/ nunca se edita a mano: es la copia cruda tal como llega de Adzuna.
# processed/ es lo que sale después de limpiar en Python.
# Esta separación ES la primera pieza de data lineage del proyecto.
mkdir -p data/raw
mkdir -p data/processed

# --- Código fuente, dividido por etapa del pipeline ---
mkdir -p src/extract
mkdir -p src/transform
mkdir -p src/load

# --- SQL, separado en definición de esquema vs. análisis ---
mkdir -p sql/schema
mkdir -p sql/analysis

# --- Documentación de la capa DAMA ---
mkdir -p docs

# --- Exploración libre, fuera del código de producción ---
mkdir -p notebooks

echo "Creando archivos base..."

# .gitkeep para que Git trackee carpetas vacías (raw/processed empiezan vacías)
touch data/raw/.gitkeep
touch data/processed/.gitkeep

# --- .gitignore ---
# Lo esencial: nunca subir credenciales ni datos crudos pesados.
if [ ! -f .gitignore ]; then
cat > .gitignore << 'EOF'
# Credenciales - NUNCA subir esto
.env

# Datos crudos (pueden pesar y no aportan valor en el repo público;
# el valor está en el código que los genera, no en los archivos en sí)
data/raw/*
!data/raw/.gitkeep

# Entornos Python
__pycache__/
*.pyc
venv/
.venv/

# Jupyter
.ipynb_checkpoints/

# Sistema
.DS_Store
EOF
echo "  .gitignore creado"
else
echo "  .gitignore ya existe, no lo toco"
fi

# --- .env.example ---
# Plantilla pública de qué variables hacen falta, SIN los valores reales.
if [ ! -f .env.example ]; then
cat > .env.example << 'EOF'
# Copia este archivo como .env y rellena con tus credenciales reales.
# El archivo .env NUNCA se sube a GitHub (ver .gitignore).

# Credenciales de Adzuna API - obtenidas en developer.adzuna.com
ADZUNA_APP_ID=tu_app_id_aqui
ADZUNA_APP_KEY=tu_app_key_aqui

# Configuración de BigQuery
BIGQUERY_PROJECT_ID=tu_project_id_aqui
BIGQUERY_DATASET=observatorio_mercado_laboral
EOF
echo "  .env.example creado"
else
echo "  .env.example ya existe, no lo toco"
fi

# --- requirements.txt ---
if [ ! -f requirements.txt ]; then
cat > requirements.txt << 'EOF'
requests
pandas
python-dotenv
google-cloud-bigquery
EOF
echo "  requirements.txt creado (versiones sin fijar por ahora, las fijamos cuando instalemos)"
else
echo "  requirements.txt ya existe, no lo toco"
fi

# --- Esqueletos de documentación DAMA ---
# Vacíos por ahora, con solo un título y una nota de propósito.
# La idea es que existan desde ya para que los vayas rellenando
# a medida que tomas decisiones, no al final.

if [ ! -f docs/data_dictionary.md ]; then
cat > docs/data_dictionary.md << 'EOF'
# Data Dictionary

> Definición de cada campo extraído y transformado en el pipeline.
> Se actualiza a medida que se toman decisiones, no al final del proyecto.

## Campos de Adzuna (raw)

_Pendiente: completar cuando hagamos la primera extracción._

## Campos normalizados (processed)

_Pendiente._
EOF
fi

if [ ! -f docs/data_lineage.md ]; then
cat > docs/data_lineage.md << 'EOF'
# Data Lineage

> Origen, transformaciones y decisiones de limpieza de cada dataset.

## Adzuna → BigQuery

_Pendiente: documentar el flujo completo cuando exista el primer script._
EOF
fi

if [ ! -f docs/data_quality.md ]; then
cat > docs/data_quality.md << 'EOF'
# Data Quality Dimensions

> Documentación explícita de completeness, consistency, timeliness y accuracy
> sobre los datos reales del proyecto.

## Completeness

_Pendiente: % de ofertas con salario, una vez tengamos la primera extracción._

## Consistency

_Pendiente._

## Timeliness

_Pendiente._

## Accuracy

_Pendiente._
EOF
fi

if [ ! -f docs/ethics_fria.md ]; then
cat > docs/ethics_fria.md << 'EOF'
# Data Ethics / FRIA aplicada

> Sección explícita sobre uso apropiado del análisis y sus limitaciones.

_Pendiente: se desarrolla en profundidad en Fase 3, pero el archivo
existe desde ahora para ir anotando reflexiones tempranas._
EOF
fi

if [ ! -f data/README.md ]; then
cat > data/README.md << 'EOF'
# Datos del proyecto

- `raw/`: copia cruda de lo que devuelve la API de Adzuna. No se edita a mano.
- `processed/`: datos limpios, listos para cargar en BigQuery.

Estos datos NO se suben a GitHub (ver .gitignore en la raíz del repo).
Este README sí se sube, para que quede documentado qué debería existir aquí.
EOF
fi

echo ""
echo "Listo. Estructura creada:"
echo ""
find . -maxdepth 3 -not -path '*/.git*' -not -path '.' | sort

echo ""
echo "Próximo paso sugerido: instalar dependencias con"
echo "  pip install -r requirements.txt"
echo "y copiar .env.example a .env con tus credenciales reales de Adzuna."
