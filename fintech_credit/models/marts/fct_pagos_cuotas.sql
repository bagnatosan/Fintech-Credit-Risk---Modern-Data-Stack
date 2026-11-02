{{ config(
    materialized='table',
    partition_by={
      "field": "fecha_vencimiento",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["estado_pago", "id_canal"]
) }}

WITH pagos AS (
    SELECT * 
    FROM {{ ref('stg_pagos') }}
),

prestamos AS (
    SELECT 
        id_solicitud,
        id_cliente,
        id_canal
    FROM {{ ref('fct_prestamos') }}
)

SELECT
    p.id_pago,
    p.id_solicitud,
    pr.id_cliente,
    pr.id_canal,

    p.numero_cuota,
    p.estado_pago,
    p.fecha_vencimiento,
    p.fecha_pago_real,
    p.monto_cuota,

    -- Cálculo dinámico de días de mora según fecha real de cobro o estado impago
    CASE 
        WHEN p.estado_pago = 'PAGADO' AND p.fecha_pago_real > p.fecha_vencimiento 
            THEN DATE_DIFF(p.fecha_pago_real, p.fecha_vencimiento, DAY)
        WHEN p.estado_pago != 'PAGADO' AND CURRENT_DATE() > p.fecha_vencimiento 
            THEN DATE_DIFF(CURRENT_DATE(), p.fecha_vencimiento, DAY)
        ELSE 0 
    END AS dias_mora,

    CASE 
        WHEN (
            (p.estado_pago = 'PAGADO' AND p.fecha_pago_real > p.fecha_vencimiento) OR 
            (p.estado_pago != 'PAGADO' AND CURRENT_DATE() > p.fecha_vencimiento)
        ) THEN TRUE 
        ELSE FALSE 
    END AS flag_cuota_con_mora,

    CASE 
        WHEN p.estado_pago != 'PAGADO' AND CURRENT_DATE() > p.fecha_vencimiento THEN TRUE 
        ELSE FALSE 
    END AS flag_cuota_vencida_impaga

FROM pagos p
INNER JOIN prestamos pr
    ON p.id_solicitud = pr.id_solicitud
