WITH limites_fechas AS (
    SELECT 
        COALESCE(MIN(DATE(fecha_solicitud)), '2024-01-01') AS fecha_inicio,
        DATE_ADD(CURRENT_DATE(), INTERVAL 3 YEAR) AS fecha_fin
    FROM {{ ref('stg_solicitudes') }}
),

rango_fechas AS (
    SELECT fecha
    FROM limites_fechas,
    UNNEST(GENERATE_DATE_ARRAY(fecha_inicio, fecha_fin, INTERVAL 1 DAY)) AS fecha
),

dimension_calendario AS (
    SELECT
        fecha AS fecha_key,
        EXTRACT(YEAR FROM fecha) AS anio,
        EXTRACT(MONTH FROM fecha) AS mes_numero,
        FORMAT_DATE('%B', fecha) AS mes_nombre,
        EXTRACT(DAY FROM fecha) AS dia_del_mes,
        EXTRACT(DAYOFWEEK FROM fecha) AS dia_de_semana_numero,
        FORMAT_DATE('%A', fecha) AS dia_de_semana_nombre,
        EXTRACT(QUARTER FROM fecha) AS trimestre,
        CONCAT('Q', CAST(EXTRACT(QUARTER FROM fecha) AS STRING), '-', CAST(EXTRACT(YEAR FROM fecha) AS STRING)) AS anio_trimestre,
        FORMAT_DATE('%Y-%m', fecha) AS anio_mes,
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM fecha) IN (1, 7) THEN TRUE 
            ELSE FALSE 
        END AS es_fin_de_semana
    FROM rango_fechas
)

SELECT * 
FROM dimension_calendario
