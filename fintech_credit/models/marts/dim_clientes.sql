WITH clientes_staging AS (
    SELECT * 
    FROM {{ ref('stg_clientes') }}
),

clientes_ordenados AS (
    SELECT
        id_cliente,
        nombre_cliente,
        provincia,
        score_bancario,
        ingresos_mensuales,
        fecha_actualizacion,
        -- Asigna 1 a la versión más reciente de cada cliente
        ROW_NUMBER() OVER (
            PARTITION BY id_cliente 
            ORDER BY fecha_actualizacion DESC
        ) as orden_version
    FROM clientes_staging
),

clientes_deduplicados AS (
    SELECT
        id_cliente,
        nombre_cliente,
        provincia,
        score_bancario,
        ingresos_mensuales,
        fecha_actualizacion AS ultima_actualizacion
    FROM clientes_ordenados
    WHERE orden_version = 1
)

SELECT * 
FROM clientes_deduplicados
