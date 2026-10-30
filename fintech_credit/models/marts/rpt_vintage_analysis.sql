WITH prestamos AS (
    SELECT 
        id_solicitud,
        FORMAT_DATE('%Y-%m', fecha_desembolso) AS cohorte_desembolso,
        monto_otorgado
    FROM {{ ref('fct_prestamos') }}
    WHERE estado_operativo_credito != 'RECHAZADO'
),

cohortes_monto AS (
    -- Capital total originado por cada cohorte (denominador de la cohorte)
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
        -- Month on Book (MOB): Meses transcurridos entre desembolso y vencimiento
        DATE_DIFF(p.fecha_vencimiento, DATE(p.fecha_vencimiento), MONTH) AS mob,
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
        -- Saldo con mora mayor a 30 días en cada MOB
        SUM(CASE WHEN c.dias_mora > 30 THEN c.monto_cuota ELSE 0 END) AS saldo_mora_30
    FROM cuotas_mora c
    WHERE c.mob BETWEEN 0 AND 24 -- Evaluación de los primeros 24 meses de vida
    GROUP BY 1, 2
)

SELECT 
    v.cohorte_desembolso,
    cm.monto_total_originado,
    v.mob,
    v.saldo_mora_30,
    -- Ratio de Mora 30+ sobre el monto original originado de la cohorte
    ROUND(SAFE_DIVIDE(v.saldo_mora_30, cm.monto_total_originado) * 100, 2) AS pct_mora_30_acumulada
FROM vintage_agrupado v
INNER JOIN cohortes_monto cm
    ON v.cohorte_desembolso = cm.cohorte_desembolso
ORDER BY 1 DESC, 2 ASC
