WITH prestamos AS (
    SELECT 
        id_solicitud,
        fecha_desembolso,
        FORMAT_DATE('%Y-%m', fecha_desembolso) AS cohorte_desembolso,
        monto_otorgado
    FROM {{ ref('fct_prestamos') }}
    WHERE fecha_desembolso IS NOT NULL
),

cohortes_monto AS (
    -- Capital total originado por cada cohorte (denominador)
    SELECT 
        cohorte_desembolso,
        SUM(monto_otorgado) AS monto_total_originado
    FROM prestamos
    GROUP BY 1
),

cuotas_mora AS (
    SELECT 
        p.id_solicitud,
        pr.cohorte_desembolso,
        -- Month on Book (MOB): Diferencia real en meses entre desembolso y vencimiento de la cuota
        DATE_DIFF(p.fecha_vencimiento, pr.fecha_desembolso, MONTH) AS mob,
        p.monto_cuota,
        p.dias_mora
    FROM {{ ref('fct_pagos_cuotas') }} p
    INNER JOIN prestamos pr
        ON p.id_solicitud = pr.id_solicitud
),

vintage_agrupado AS (
    SELECT 
        c.cohorte_desembolso,
        c.mob,
        -- Saldo en mora > 30 días
        SUM(CASE WHEN c.dias_mora > 30 THEN c.monto_cuota ELSE 0 END) AS saldo_mora_30
    FROM cuotas_mora c
    WHERE c.mob >= 0 AND c.mob <= 24
    GROUP BY 1, 2
)

SELECT 
    v.cohorte_desembolso,
    cm.monto_total_originado,
    v.mob,
    v.saldo_mora_30,
    -- Porcentaje de mora 30+ acumulada sobre el monto originado
    ROUND(SAFE_DIVIDE(v.saldo_mora_30, cm.monto_total_originado) * 100, 2) AS pct_mora_30_acumulada
FROM vintage_agrupado v
INNER JOIN cohortes_monto cm
    ON v.cohorte_desembolso = cm.cohorte_desembolso
ORDER BY 1 DESC, 3 ASC
