{{ config(
    materialized='table',
    partition_by={
      "field": "fecha_desembolso",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["estado_operativo_credito", "id_canal"]
) }}

WITH solicitudes_enriquecidas AS (
    SELECT * 
    FROM {{ ref('int_solicitudes_enriquecidas') }}
),

clientes AS (
    SELECT id_cliente 
    FROM {{ ref('dim_clientes') }}
),

fct_prestamos AS (
    SELECT
        -- Clave Primaria del Hecho
        se.id_solicitud,

        -- Claves Foráneas (FK) a Dimensiones
        se.id_cliente,
        CASE 
            WHEN se.id_canal = 999 OR se.id_canal IS NULL THEN -1
            ELSE se.id_canal 
        END AS id_canal,

        -- Fechas de Control de Ciclo de Vida
        se.fecha_solicitud,
        se.fecha_desembolso,

        -- Atributos de Estado y Calidad de Cartera
        se.estado_solicitud,
        se.estado_operativo_credito,
        se.flag_default_tecnico,

        -- Condiciones Contractuales de Origen
        se.tasa_nominal_anual,
        se.plazo_meses,

        -- Métricas Cuantitativas y Exposición Monetaria
        se.monto_solicitado,
        se.monto_otorgado,
        se.monto_total_pagado,
        se.monto_saldo_pendiente,

        -- Métricas de Desempeño y Morosidad
        se.dias_mora_maxima,
        se.total_cuotas_generadas,
        se.cuotas_pagadas,
        se.cuotas_en_mora,
        se.cuotas_pendientes,

        -- Hitos de Cobranza
        se.primera_cuota_vencimiento,
        se.ultima_cuota_vencimiento,
        se.ultimo_pago_realizado

    FROM solicitudes_enriquecidas se
        INNER JOIN clientes c
        ON se.id_cliente = c.id_cliente
)

SELECT * 
FROM fct_prestamos
