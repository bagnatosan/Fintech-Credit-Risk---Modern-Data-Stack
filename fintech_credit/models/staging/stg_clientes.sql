WITH source_clientes AS (
    SELECT
        id_ingesta,
        ingested_at,
        source_system,
        payload_json
    FROM {{ source('raw_vault', 'raw_clientes') }}
),

parsed_and_cast AS (
    SELECT
        -- Metadatos de auditoría
        id_ingesta,
        ingested_at,
        source_system,

        -- Identificador de negocio (Clave natural)
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_cliente') AS INT64) AS id_cliente,

        -- Datos demográficos y geográficos
        TRIM(JSON_VALUE(payload_json, '$.nombre')) AS nombre_cliente,
        UPPER(TRIM(JSON_VALUE(payload_json, '$.provincia'))) AS provincia,

        -- Métricas crediticias y de riesgo
        SAFE_CAST(JSON_VALUE(payload_json, '$.score_bancario') AS INT64) AS score_bancario,
        SAFE_CAST(JSON_VALUE(payload_json, '$.ingresos_mensuales') AS NUMERIC) AS ingresos_mensuales,

        -- Timestamp del evento reportado
        SAFE_CAST(JSON_VALUE(payload_json, '$.fecha_actualizacion') AS TIMESTAMP) AS fecha_actualizacion

    FROM source_clientes
)

SELECT * FROM parsed_and_cast
