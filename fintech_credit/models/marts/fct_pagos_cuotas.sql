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

-- Filtramos solo los préstamos válidos ya consolidados en la Gold
prestamos AS (
    SELECT 
        id_solicitud,
        id_cliente,
        id_canal
    FROM {{ ref('fct_prestamos') }}
)

SELECT
    -- Clave Primaria del Hecho Transaccional
    p.id_pago,

    -- Claves Foráneas (FK) a Dimensiones y Hecho de Préstamos
    p.id_solicitud,
    pr.id_cliente,
    pr.id_canal,

    -- Atributos de la Cuota
    p.numero_cuota,
    p.estado_pago,
    
    -- Fechas de Vencimiento y Cobro
    p.fecha_vencimiento,
    p.fecha_pago_real,

    -- Métricas Monetarias
    p.monto_cuota,

    -- Indicadores de Riesgo por Cuota
    p.dias_mora,
    CASE 
        WHEN p.dias_mora > 0 THEN TRUE 
        ELSE FALSE 
    END AS flag_cuota_con_mora,
    CASE 
        WHEN p.estado_pago != 'PAGADO' AND CURRENT_DATE() > p.fecha_vencimiento THEN TRUE 
        ELSE FALSE 
    END AS flag_cuota_vencida_impaga

FROM pagos p
-- INNER JOIN elimina las cuotas de solicitudes rechazadas o inexistentes en fct_prestamos
INNER JOIN prestamos pr
    ON p.id_solicitud = pr.id_solicitud
