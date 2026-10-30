WITH prestamos AS (
    SELECT 
        p.id_solicitud,
        p.id_cliente,
        p.id_canal,
        c.nombre_canal,
        p.estado_operativo_credito,
        p.monto_otorgado,
        p.monto_total_pagado,
        p.monto_saldo_pendiente,
        p.dias_mora_maxima,
        p.flag_default_tecnico
    FROM {{ ref('fct_prestamos') }} p
    LEFT JOIN {{ ref('dim_canales') }} c
        ON p.id_canal = c.id_canal
)

SELECT 
    nombre_canal,
    COUNT(id_solicitud) AS total_operaciones,
    SUM(monto_otorgado) AS volumen_originado,
    SUM(monto_saldo_pendiente) AS cartera_activa_total,
    
    -- Saldo en Mora > 90 días (Default)
    SUM(CASE WHEN flag_default_tecnico THEN monto_saldo_pendiente ELSE 0 END) AS saldo_npl_90,
    
    -- NPL Ratio % (Mora 90+ sobre Cartera Activa)
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN flag_default_tecnico THEN monto_saldo_pendiente ELSE 0 END),
            SUM(monto_saldo_pendiente)
        ) * 100, 2
    ) AS npl_ratio_90_pct

FROM prestamos
GROUP BY 1
