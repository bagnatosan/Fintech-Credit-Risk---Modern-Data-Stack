{{ config(
    materialized='table',
) }}

WITH solicitudes AS (
    SELECT * 
    FROM {{ ref('stg_solicitudes') }}
    WHERE UPPER(TRIM(estado_solicitud)) = 'APROBADO'
),

pagos_agrupados AS (
    SELECT * 
    FROM {{ ref('int_pagos_por_solicitud') }}
),

canales AS (
    SELECT id_canal 
    FROM {{ ref('dim_canales') }}
)

SELECT
    s.id_solicitud,
    s.id_cliente,
    
    CASE 
        WHEN c.id_canal IS NOT NULL THEN s.id_canal
        ELSE -1 
    END AS id_canal,

    s.estado_solicitud AS estado_operativo_credito,
    s.fecha_solicitud,
    COALESCE(s.fecha_desembolso, s.fecha_solicitud) AS fecha_desembolso,
    
    COALESCE(s.monto_otorgado, s.monto_solicitado, 0) AS monto_otorgado,
    COALESCE(p.monto_total_pagado, 0) AS monto_total_pagado,
    COALESCE(p.monto_saldo_pendiente, 0) AS monto_saldo_pendiente,
    COALESCE(p.dias_mora_maxima, 0) AS dias_mora_maxima,
    
    CASE 
        WHEN COALESCE(p.dias_mora_maxima, 0) >= 90 THEN TRUE 
        ELSE FALSE 
    END AS flag_default_tecnico

FROM solicitudes s
LEFT JOIN pagos_agrupados p
    ON s.id_solicitud = p.id_solicitud
LEFT JOIN canales c
    ON s.id_canal = c.id_canal
