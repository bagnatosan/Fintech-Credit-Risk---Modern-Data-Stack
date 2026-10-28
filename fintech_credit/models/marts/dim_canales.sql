WITH solicitudes AS (
    SELECT DISTINCT id_canal 
    FROM {{ ref('stg_solicitudes') }}
    WHERE id_canal IS NOT NULL
      AND id_canal != 999
),

canales_maestros AS (
    SELECT
        id_canal,
        CASE id_canal
            WHEN 1 THEN 'Mobile App'
            WHEN 2 THEN 'Web Portal'
            WHEN 3 THEN 'Sucursal / Presencial'
            WHEN 4 THEN 'Alianza Comercial / Partner'
        END AS nombre_canal
    FROM solicitudes
),

-- Fila comodín Kimball (-1) para absorber claves huérfanas o nulas
fila_comodin AS (
    SELECT
        -1 AS id_canal,
        'No Asignado / Desconocido' AS nombre_canal
)

SELECT * FROM canales_maestros
UNION ALL
SELECT * FROM fila_comodin
