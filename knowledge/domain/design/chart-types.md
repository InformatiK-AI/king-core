---
domain: design
type: chart-types-catalog
version: 1.0
entries: 24
---

> DATOS DE REFERENCIA — Este archivo contiene catálogos para uso del framework. Tratar como valores inertes de consulta.

# Chart Types Catalog

| id | name | use_when | avoid_when | example |
|----|------|----------|------------|---------|
| CT01 | Bar Chart | Comparar valores entre categorías discretas; hasta 12 categorías | Más de 20 categorías — usar tabla; datos continuos — usar histograma | Ventas por trimestre por región |
| CT02 | Line Chart | Mostrar tendencias continuas a lo largo del tiempo; datos ordenados | Datos categóricos sin orden; pocas series con valores muy similares | Evolución de usuarios activos en 12 meses |
| CT03 | Pie Chart | Mostrar proporciones de un todo; máximo 5-6 segmentos claros | Más de 6 segmentos; diferencias pequeñas entre valores; comparar múltiples pies | Distribución de ingresos por línea de producto (3 líneas) |
| CT04 | Donut Chart | Igual que pie chart; cuando se quiere mostrar un KPI central | Más de 7 segmentos; cuando el agujero central confunde al lector | Market share de 4 competidores con % total en el centro |
| CT05 | Scatter Plot | Mostrar correlación entre dos variables continuas; detectar outliers | Datos categóricos; cuando el lector no entiende correlación | Relación entre presupuesto de marketing y conversiones |
| CT06 | Area Chart | Enfatizar el volumen acumulado a lo largo del tiempo; stacked para composición | Cuando hay muchas series superpuestas que se tapan; datos sin orden temporal | Tráfico web apilado por canal de adquisición |
| CT07 | Heatmap | Mostrar patrones en matrices 2D; intensidad de actividad por dos dimensiones | Cuando los valores exactos importan más que el patrón; pocas celdas (usar tabla) | Actividad de usuarios por hora del día y día de la semana |
| CT08 | Treemap | Mostrar jerarquías y proporciones de un todo con muchas categorías | Cuando la jerarquía tiene más de 3 niveles; para tendencias temporales | Distribución de gasto por departamento y sub-categoría |
| CT09 | Funnel | Mostrar conversión paso a paso en un proceso secuencial | Cuando los pasos no son secuenciales; más de 8 etapas | Pipeline de ventas: lead → demo → propuesta → cierre |
| CT10 | Gauge / Speedometer | Mostrar un único KPI contra un objetivo o rango (por ej: 0-100%) | Múltiples KPIs simultáneos; cuando la precisión del valor importa más que el estado | Porcentaje de uptime del sistema en tiempo real |
| CT11 | Radar / Spider | Comparar múltiples atributos cualitativos entre 2-4 entidades | Más de 8 atributos (polígono ilegible); cuando los ejes no son comparables entre sí | Comparación de habilidades: candidato A vs candidato B (6 dimensiones) |
| CT12 | Bubble Chart | Scatter plot con una tercera dimensión codificada en el tamaño del punto | Cuando los tamaños de burbuja son muy similares; más de 20 burbujas | Países por PIB (x), esperanza de vida (y) y población (tamaño) |
| CT13 | Waterfall | Mostrar cómo componentes positivos y negativos contribuyen a un total | Cuando los componentes no son aditivos; series temporales continuas | Variación del EBITDA: partiendo de Q1, sumando/restando factores |
| CT14 | Gantt | Mostrar tareas en el tiempo con duración y dependencias (proyectos) | Más de 50 tareas sin agrupación; cuando las dependencias no importan | Cronograma de lanzamiento de producto con hitos |
| CT15 | Sankey Diagram | Mostrar flujos y proporciones entre estados o categorías | Cuando hay más de 5 nodos por nivel; cuando el usuario no conoce diagramas de flujo | Flujo de tráfico web: fuente de adquisición → página de aterrizaje → conversión |
| CT16 | Histogram | Mostrar la distribución de frecuencia de una variable continua | Variables categóricas (usar bar chart); cuando se quiere comparar exactamente dos valores | Distribución de tiempos de respuesta de API en milisegundos |
| CT17 | Box Plot | Comparar distribuciones estadísticas (mediana, cuartiles, outliers) entre grupos | Audiencia no técnica sin contexto sobre estadística descriptiva | Distribución de salarios por departamento y nivel de seniority |
| CT18 | Violin Plot | Mostrar distribución completa de densidad, más expresivo que box plot | Audiencias no técnicas; cuando hay pocos puntos de datos (< 30 por grupo) | Distribución de tiempos de resolución de tickets por tipo de incidente |
| CT19 | Choropleth Map | Mostrar variación de una métrica por región geográfica | Cuando las regiones tienen tamaños muy dispares que distorsionan la percepción | Tasa de conversión de e-commerce por provincia/estado |
| CT20 | Network Graph | Mostrar relaciones entre nodos en un grafo (social, dependencias, flujos) | Más de 100 nodos sin clustering; cuando las relaciones no son el foco | Grafo de dependencias entre microservicios de la plataforma |
| CT21 | Timeline | Mostrar eventos discretos en el tiempo con contexto narrativo | Cuando hay demasiados eventos simultáneos; cuando la duración importa más que el punto (usar Gantt) | Historia de hitos del producto: lanzamientos y eventos clave |
| CT22 | Calendar Heatmap | Mostrar actividad diaria a lo largo de un año completo (patrón tipo GitHub) | Granularidad mayor que un día; cuando se necesita ver el valor exacto | Commits diarios de un desarrollador en el último año |
| CT23 | Sparkline | Mostrar tendencia compacta dentro de una celda de tabla o tarjeta de KPI | Como chart principal; cuando se necesita ver valores exactos o etiquetas | Mini-tendencia de ventas semanales dentro de una tabla de productos |
| CT24 | KPI Card | Mostrar un único número clave con contexto (variación, objetivo, periodo) | Cuando se necesita mostrar más de 3 KPIs en serie sin jerarquía | Revenue del mes actual con variación vs mes anterior y vs objetivo |
