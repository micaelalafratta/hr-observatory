# Observatorio del Mercado Laboral de Datos y Gobernanza en España
## Documento de contexto y hoja de ruta del proyecto

---

## Qué es este proyecto

Un observatorio del mercado laboral enfocado en perfiles de datos, tecnología y gobernanza en España, construido aplicando principios DAMA/CDMP en el propio pipeline. Combina análisis de oferta de empleo real con datos macroeconómicos, índices de exposición a IA y una capa editorial de normativa por sector.

**Narrativa central:** El mercado laboral español es opaco en salarios, en lo que realmente se pide, y en cómo la automatización está transformando los empleos de forma desigual según género y sector. Este proyecto lo mide con datos reales y lo analiza con criterio de derechos fundamentales.

**Por qué este proyecto y no otro:** Es el único que demuestra simultáneamente capacidad técnica (pipeline completo), comprensión del marco DAMA, análisis de sesgo estructural con datos reales, y razonamiento ético sobre las implicaciones de los datos analizados. Además sirve como justificación activa del período sin empleo durante entrevistas.

---

## Fuentes de datos confirmadas

### Fuente principal (extracción automatizada)
**Adzuna API**
- Registro gratuito en developer.adzuna.com
- Cubre España con datos de ofertas de empleo: título, empresa, localización, descripción, categoría, salario (cuando existe)
- Endpoints útiles: búsqueda de ofertas, salarios históricos, datos regionales, top companies por volumen de contratación
- Limitación real: en España el salario aparece en pocas ofertas (opacidad salarial estructural). Esto se documenta como hallazgo, no se oculta
- Estrategia: buscar por categorías amplias (datos, tecnología, RRHH) y filtrar por keywords en Python, no buscar solo el nicho directamente en la API

### Fuente macroeconómica (descarga trimestral manual)
**INE - Encuesta de Población Activa (EPA)**
- Microdatos descargables gratuitamente en CSV desde ine.es
- Periodicidad trimestral, datos desde 2021
- Variables: ocupación, sector, tipo de contrato, nivel educativo, comunidad autónoma, sexo, edad
- Clasificación de actividades: CNAE-2009 hasta 2025, CNAE-2025 desde T1 2026
- Clasificación de ocupaciones: CNO-2011
- Limitación: datos agregados por encuesta, no granularidad de puesto concreto

### Fuente de referencia (carga única)
**OIT - Índice de exposición a IA generativa por ocupación (2025)**
- Descarga gratuita desde ilo.org
- Clasificación ISCO-08 (compatible con Europa)
- Puntuaciones de exposición a automatización por categoría ocupacional
- Actualización anual, no requiere automatización
- Incluye dimensión de género en la exposición

### Fuente complementaria (descarga manual, opcional)
**SEPE - Estadísticas de empleo**
- Contratos registrados por sector y ocupación, trimestral
- Descarga en Excel desde sepe.es
- Útil para distribución de tipos de contrato por sector en España
- No tiene API programática

### Tabla editorial (construcción y mantenimiento propio)
**Normativa por sector**
- Tabla construida manualmente en BigQuery
- Una fila por sector económico
- Columnas: normativas aplicables (GDPR, AI Act por nivel de riesgo, DORA para finanzas, MDR para salud, NIS2, etc.)
- Fuente de valor diferencial: requiere criterio de gobernanza, no solo técnica

---

## Problema de taxonomías (MDM)

Las tres fuentes principales usan clasificaciones distintas que hay que mapear:

| Fuente | Clasificación ocupacional |
|--------|--------------------------|
| EPA/INE | CNO-2011 |
| OIT | ISCO-08 |
| Adzuna | Categorías propias |

Este mapeo es un ejercicio real de Master Data Management y se documenta como parte de la capa DAMA del proyecto.

---

## Infraestructura técnica

| Componente | Herramienta | Estado |
|-----------|-------------|--------|
| Extracción | Python + requests/API | Por construir |
| Limpieza | Python + Pandas | Por construir |
| Almacén | Google BigQuery | Cuenta activa |
| Automatización | Google Cloud Scheduler (futuro) | Aprendizaje posterior |
| Visualización | Por decidir (Looker Studio / Streamlit) | Fase 2 |
| Documentación | GitHub README + data dictionary | Fase 1 |

**Decisión sobre cloud:** BigQuery sobre Azure. Razón: cuenta activa, menor curva de entrada, conceptos transferibles. Azure se aprende en paralelo con proyecto más pequeño y enfocado.

---

## Dimensiones de análisis

### Análisis que salen solo de Adzuna (Fase 1)
- Qué categorías de empleo mencionan IA como habilidad requerida
- Evolución de menciones a "GDPR", "AI Act", "gobernanza", "data governance", "DPO", "data steward" en ofertas españolas
- Opacidad salarial: porcentaje de ofertas sin salario por sector
- Qué empresas están contratando más perfiles de datos y gobernanza en España
- Distribución geográfica de las ofertas

### Análisis cruzado (Fase 2)
- Cruce Adzuna + OIT: ¿los sectores con mayor riesgo de automatización están publicando más o menos ofertas?
- Cruce EPA + OIT: dimensión de género en exposición a automatización en España
- ¿El mercado español confirma o contradice las predicciones globales de los modelos de exposición?

### Índice compuesto propio (Fase 3)
Un índice de "presión de automatización por sector en España" combinando:
- Riesgo teórico (OIT)
- Contratación real (Adzuna)
- Densidad de menciones a IA en ofertas (análisis de texto)

Escala 0-100 por sector. Metodología original, documentada y citeable.

---

## Capa DAMA/CDMP aplicada al proyecto

El proyecto no solo analiza el mercado, también demuestra buenas prácticas de gestión de datos en su propio proceso.

### Data Dictionary
Definición explícita de cada campo extraído y transformado:
- Qué significa "mención de IA" (lista de términos, criterios de inclusión y exclusión)
- Cómo se normaliza el título de puesto
- Qué convención se usa para categorías cuando Adzuna no las devuelve
- Cómo se trata un campo salario nulo

### Data Quality Dimensions (DAMA)
Documentadas explícitamente sobre los propios datos:
- **Completeness:** % de ofertas con salario (se anticipa bajo en España, documentado como hallazgo)
- **Consistency:** tratamiento de nombres de empresa con variaciones (ej. "BBVA" vs "Banco BBVA")
- **Timeliness:** frecuencia de actualización de cada fuente y qué implica para el análisis
- **Accuracy:** limitaciones de aplicar el índice OIT (clasificación internacional) al mercado español

### Data Lineage
Documentación de origen, transformaciones y decisiones de limpieza para cada dataset. Publicada en el README de GitHub.

### Master Data Management
Mapeo documentado entre CNO-2011 (EPA), ISCO-08 (OIT) y categorías Adzuna. Decisiones de equivalencia justificadas.

### Data Ethics (aplicación de FRIA)
Sección explícita en el README:
- Los scores de exposición a IA son predictivos a nivel ocupacional, no individual
- Usarlos para tomar decisiones sobre personas concretas sería un mal uso
- Limitaciones del análisis de género con datos agregados

---

## Conexión con AI Act

El AI Act clasifica sistemas de IA por nivel de riesgo (prohibido, alto riesgo, limitado, mínimo). Esa clasificación ya existe por sector y tipo de aplicación.

Cruzando eso con los sectores que más contratan en España y los que tienen mayor exposición a automatización, el proyecto puede inferir qué empresas españolas van a necesitar más urgentemente perfiles de gobernanza en los próximos dos años. No como predicción especulativa, sino como consecuencia directa de la regulación vigente.

---

## Capa de análisis de sesgo (bias)

El proyecto incluye una dimensión de análisis de sesgo estructural en el mercado laboral español. No es un proyecto de evaluación de LLMs, sino de bias en datos y sistemas con impacto real en personas.

### Contexto jurisprudencial relevante

En julio de 2025, la Audiencia Nacional española dictó sentencia en el caso CGT contra Foundever: la empresa negó usar algoritmos en la gestión de RRHH, el tribunal declaró la práctica nula por vulneración de la libertad sindical, y ordenó la divulgación de los parámetros del algoritmo a los representantes de los trabajadores. Es la primera sentencia española que reconoce el derecho sindical a información sobre algoritmos de RRHH. El contexto regulatorio refuerza esta urgencia: el 2 de agosto de 2026 es la fecha límite para que las empresas con IA en contratación tengan en marcha bias testing, documentación técnica y supervisión humana.

Esto convierte el análisis de sesgo en algo con urgencia legal real en España, no solo en interés académico.

### Tipos de sesgo que el proyecto puede medir con los datos disponibles

**Sesgo de género en exposición a automatización (EPA + OIT)**
Cruce de microdatos EPA desagregados por sexo con el índice de exposición a IA de la OIT por ocupación. Permite visualizar qué grupos son más vulnerables a la automatización en España y si coincide con los grupos ya en situación de mayor precariedad laboral.

**Sesgo en la demanda de perfiles técnicos (Adzuna)**
Análisis de lenguaje en las descripciones de ofertas: términos asociados a géneros específicos, requisitos que pueden funcionar como filtros indirectos, y diferencias en el rango salarial ofrecido para perfiles equivalentes en sectores distintos.

**Sesgo de opacidad salarial por sector (Adzuna)**
La ausencia de salario en una oferta no es neutral: documentar en qué sectores y perfiles es más frecuente la omisión permite inferir dónde la opacidad actúa como mecanismo de desigualdad estructural.

**Sesgo en la adopción de IA por sector (Adzuna + tabla normativa)**
Cruce de qué sectores mencionan IA en sus ofertas con qué sectores tienen mayor obligación regulatoria bajo el AI Act. Identifica dónde la adopción va por delante de la gobernanza y dónde ocurre lo contrario.

### Lo que este análisis no hace

El proyecto no evalúa el comportamiento interno de ningún algoritmo de contratación concreto, porque no hay acceso a esos datos. Mide patrones estructurales en el mercado laboral desde fuentes públicas. Eso es lo que se puede hacer honestamente con los datos disponibles, y es suficientemente significativo para tener valor propio.

### Conexión con FRIA (Fundamental Rights Impact Assessment)

La metodología FRIA aplicada al proyecto sería: identificar los grupos potencialmente afectados (mujeres en ocupaciones de alta exposición, trabajadores en sectores sin gobernanza de IA), medir el impacto diferencial con datos reales, y documentar las limitaciones del análisis. Esa sección se publica en el README como parte de la capa de ética del proyecto.

---

## Hoja de ruta por fases

### FASE 1: Versión publicable (Semanas 1-4)

**Semana 1**
- Registro en Adzuna API, obtención de App ID y App Key
- Primera extracción con Python para España: ofertas de datos, tecnología y RRHH
- Exploración del volumen y estructura de los datos recibidos
- Post en LinkedIn: "Arranco este proyecto. Primera extracción hecha."

**Semana 2**
- Limpieza en Python: normalización de títulos, tratamiento de nulos, extracción de keywords de las descripciones
- Carga inicial en BigQuery: diseño del esquema de tablas
- Primer análisis SQL: categorías más frecuentes, distribución geográfica, % de ofertas con salario

**Semana 3**
- Análisis de menciones a IA y gobernanza en descripciones de ofertas
- Análisis de top companies por volumen de contratación en perfiles de datos
- Inicio del data dictionary y README
- Post en LinkedIn: primer hallazgo concreto con número (ej. "X% de las ofertas de datos en España no incluyen salario")

**Semana 4**
- README completo con lineage, limitaciones, data dictionary básico y capa ética
- Repositorio de GitHub publicado y ordenado
- Post de LinkedIn con el proyecto publicado y los hallazgos principales
- Preparación de cómo explicarlo en entrevistas

**Entregable de Fase 1:** repositorio GitHub público, análisis SQL documentado, README con capa DAMA, dos o tres posts en LinkedIn con hallazgos reales.

---

### FASE 2: Primera profundización (Mes 2)

- Automatización del pipeline con Google Cloud Scheduler
- Incorporación de la EPA: carga de microdatos y cruce con datos de Adzuna
- Carga del índice de exposición a IA de la OIT
- Tabla de normativa por sector (construcción editorial)
- Conexión con AI Act: qué sectores tienen mayor urgencia regulatoria
- Primer análisis de sesgo de género en exposición a automatización (EPA + OIT)
- Primera visualización del dashboard (Looker Studio o Streamlit)
- Publicación en LinkedIn de un análisis más profundo

---

### FASE 3: Proyecto maduro (Mes 3 en adelante)

- Cruce EPA + OIT: dimensión de género y vulnerabilidad por sector en España
- Análisis de lenguaje en ofertas: detección de términos con sesgo implícito en descripciones de puestos
- Aplicación de metodología FRIA documentada sobre los hallazgos de sesgo
- Índice compuesto propio de presión de automatización
- Informe trimestral automatizado: el pipeline genera un resumen de hallazgos nuevos cada trimestre
- El informe como serie publicable en LinkedIn

---

## Narrativa para entrevistas

**Pregunta habitual:** "¿Qué has estado haciendo mientras buscabas trabajo?"

**Respuesta con este proyecto:** "Construí un observatorio del mercado laboral de datos y gobernanza en España. Extraigo ofertas de empleo de forma automatizada, las cruzo con datos de la EPA y con el índice de exposición a IA de la OIT, y documento todo el pipeline aplicando principios DAMA: data dictionary, calidad de datos, lineage y una sección de ética aplicada. Hay una dimensión de análisis de sesgo estructural: qué grupos son más vulnerables a la automatización en España según los datos reales del mercado, y cómo la opacidad salarial funciona de forma diferente según sector y perfil. Todo está publicado en GitHub con las decisiones y limitaciones documentadas."

Eso responde tres preguntas a la vez: qué has aprendido, cómo trabajas, y qué te importa.

---

## Lo que el proyecto demuestra en el CV y LinkedIn

| Competencia | Cómo la demuestra |
|-------------|-------------------|
| SQL | Queries documentadas sobre BigQuery |
| Python | Pipeline de extracción y limpieza publicado |
| BigQuery | Almacén central del proyecto |
| APIs | Extracción desde Adzuna |
| DAMA/CDMP | Data dictionary, lineage, quality dimensions documentados |
| AI Act y GDPR | Tabla de normativa por sector y sección de ética |
| Análisis de sesgo | Cruce EPA + OIT con dimensión de género, análisis de lenguaje en ofertas |
| FRIA aplicada | Metodología de impacto en derechos fundamentales documentada en el README |
| Análisis crítico | Índice propio y limitaciones explícitas |
| Comunicación | Posts en LinkedIn con hallazgos para audiencia no técnica |

---

## Nombre provisional del proyecto

**"Lo que el mercado laboral español no dice"**
Subtítulo: Observatorio de datos, IA y gobernanza en el mercado de trabajo español.

Alternativa más técnica: **Spain Data & AI Labour Observatory**

---

*Documento generado en conversación con Claude. Última actualización: junio 2026. Incluye capa de análisis de sesgo y contexto jurisprudencial español.*
