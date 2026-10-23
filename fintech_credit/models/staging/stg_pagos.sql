WITH source_pagos AS (
    SELECT
        id_ingesta,
        ingested_at,
        source_system,
        payload_json
    FROM {{ source('raw_vault', 'raw_pagos') }}
),

parsed_and_cast AS (
    SELECT
        -- Metadatos de auditoría
        id_ingesta,
        ingested_at,
        source_system,

        -- Identificadores
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_pago') AS INT64) AS id_pago,
        SAFE_CAST(JSON_VALUE(payload_json, '$.id_solicitud') AS INT64) AS id_solicitud,

        -- Métricas transaccionales
        SAFE_CAST(JSON_VALUE(payload_json, '$.numero_cuota') AS INT64) AS numero_cuota,
        SAFE_CAST(JSON_VALUE(payload_json, '$.monto_cuota') AS NUMERIC) AS monto_cuota,
        SAFE_CAST(JSON_VALUE(payload_json, '$.dias_mora') AS INT64) AS dias_mora,

        -- Estado de la cuota
        UPPER(TRIM(JSON_VALUE(payload_json, '$.estado_pago'))) AS estado_pago,

        -- Fechas del ciclo de cobro
        SAFE_CAST(JSON_VALUE(payload_json, '$.fecha_vencimiento') AS DATE) AS fecha_vencimiento,
        SAFE_CAST(JSON_VALUE(payload_json, '$.fecha_pago_real') AS DATE) AS fecha_pago_real

    FROM source_pagos
)

SELECT * FROM parsed_and_cast
