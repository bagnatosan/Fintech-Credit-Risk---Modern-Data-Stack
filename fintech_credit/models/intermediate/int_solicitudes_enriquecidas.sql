WITH solicitudes AS (
    SELECT * 
    FROM {{ ref('stg_solicitudes') }}
),

pagos_agregados AS (
    SELECT * 
    FROM {{ ref('int_pagos_por_solicitud') }}
),

solicitudes_enriquecidas AS (
    SELECT
        -- Identificadores principales
        s.id_solicitud,
        s.id_cliente,
        s.id_canal,

        -- Atributos de origen del crédito
        s.estado_solicitud,
        s.monto_solicitado,
        s.monto_otorgado,
        s.tasa_nominal_anual,
        s.plazo_meses,
        s.fecha_solicitud,
        s.fecha_desembolso,

        -- Métricas de pagos y mora (saneadas con COALESCE)
        COALESCE(p.dias_mora_maxima, 0) AS dias_mora_maxima,
        COALESCE(p.total_cuotas, 0) AS total_cuotas_generadas,
        COALESCE(p.cuotas_pagadas, 0) AS cuotas_pagadas,
        COALESCE(p.cuotas_en_mora, 0) AS cuotas_en_mora,
        COALESCE(p.cuotas_pendientes, 0) AS cuotas_pendientes,
        COALESCE(p.monto_total_pagado, 0.00) AS monto_total_pagado,
        
        -- Saldo pendiente: Si no hay pagos registrados, la exposición es el monto otorgado completo
        COALESCE(p.monto_saldo_pendiente, COALESCE(s.monto_otorgado, 0.00)) AS monto_saldo_pendiente,

        -- Flag de Default Técnico (Mora >= 90 días)
        CASE 
            WHEN COALESCE(p.dias_mora_maxima, 0) >= 90 THEN TRUE 
            ELSE FALSE 
        END AS flag_default_tecnico,

        -- Estado operativo del crédito
        CASE 
            WHEN s.estado_solicitud = 'APROBADO' AND COALESCE(p.cuotas_en_mora, 0) > 0 THEN 'EN_MORA'
            WHEN s.estado_solicitud = 'APROBADO' AND COALESCE(p.monto_saldo_pendiente, 0) = 0 AND COALESCE(p.cuotas_pagadas, 0) > 0 THEN 'CANCELADO'
            WHEN s.estado_solicitud = 'APROBADO' THEN 'VIGENTE_AL_DIA'
            ELSE s.estado_solicitud
        END AS estado_operativo_credito,

        -- Fechas de trazabilidad de cobranza
        p.primera_cuota_vencimiento,
        p.ultima_cuota_vencimiento,
        p.ultimo_pago_realizado

    FROM solicitudes s
    LEFT JOIN pagos_agregados p
        ON s.id_solicitud = p.id_solicitud
)

SELECT * 
FROM solicitudes_enriquecidas
