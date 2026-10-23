/*
  Regla de Negocio:
  Ninguna solicitud de crédito puede tener una tasa nominal anual menor a cero.
*/

SELECT
    id_solicitud,
    tasa_nominal_anual
FROM {{ ref('stg_solicitudes') }}
WHERE tasa_nominal_anual < 0
