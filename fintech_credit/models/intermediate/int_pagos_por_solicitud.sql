WITH pagos AS (
    SELECT * 
    FROM {{ ref('stg_pagos') }}
),

agregado_por_solicitud AS (
    SELECT
        id_solicitud,

        -- Métricas de morosidad y riesgo crediticio
        MAX(dias_mora) AS dias_mora_maxima,
        
        -- Distribución del plan de cuotas
        COUNT(id_pago) AS total_cuotas,
        COUNTIF(estado_pago = 'PAGADO') AS cuotas_pagadas,
        COUNTIF(estado_pago = 'MORA') AS cuotas_en_mora,
        COUNTIF(estado_pago = 'PENDIENTE') AS cuotas_pendientes,

        -- Exposición monetaria y cobranza
        ROUND(SUM(CASE WHEN estado_pago = 'PAGADO' THEN monto_cuota ELSE 0 END), 2) AS monto_total_pagado,
        ROUND(SUM(CASE WHEN estado_pago != 'PAGADO' THEN monto_cuota ELSE 0 END), 2) AS monto_saldo_pendiente,

        -- Marcas temporales del cronograma
        MIN(fecha_vencimiento) AS primera_cuota_vencimiento,
        MAX(fecha_vencimiento) AS ultima_cuota_vencimiento,
        MAX(fecha_pago_real) AS ultimo_pago_realizado

    FROM pagos
    GROUP BY id_solicitud
)

SELECT * 
FROM agregado_por_solicitud
