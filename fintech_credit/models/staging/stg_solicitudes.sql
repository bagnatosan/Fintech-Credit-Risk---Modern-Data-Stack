WITH source_data AS (
    SELECT
        id_ingesta,
        ingested_at,
        source_system,
        payload_json
    FROM {{ source('raw_vault', 'raw_solicitudes') }}
),

parsed_and_cast AS (
    SELECT
        -- Metadatos de auditoría
        id_ingesta,
        ingested_at,
        source_system,

        -- Identificadores extraídos del JSON
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_solicitud') AS INT64) AS id_solicitud,
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_cliente') AS INT64) AS id_cliente,
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_canal') AS INT64) AS id_canal,

        -- Métricas financieras
        SAFE_CAST(JSON_VALUE(payload_json, '$.monto_solicitado') AS NUMERIC) AS monto_solicitado,
        SAFE_CAST(JSON_VALUE(payload_json, '$.monto_otorgado') AS NUMERIC) AS monto_otorgado,
        SAFE_CAST(JSON_VALUE(payload_json, '$.tasa_nominal_anual') AS FLOAT64) AS tasa_nominal_anual,
        SAFE_CAST(JSON_VALUE(payload_json, '$.plazo_meses') AS INT64) AS plazo_meses,

        -- Dimensiones y estados
        UPPER(TRIM(JSON_VALUE(payload_json, '$.estado'))) AS estado_solicitud,
        SAFE_CAST(JSON_VALUE(payload_json, '$.fecha_solicitud') AS DATE) AS fecha_solicitud,
        SAFE_CAST(JSON_VALUE(payload_json, '$.fecha_desembolso') AS DATE) AS fecha_desembolso

    FROM source_data
)

SELECT * FROM parsed_and_cast
