/*
	Regla de negocio: Un crédito no puede haberse desembolsado antes de que el cliente lo haya solicitado. 
*/

SELECT id_solicitud, fecha_desembolso, fecha_solicitud
FROM {{ ref('stg_solicitudes') }}
WHERE fecha_desembolso < fecha_solicitud
AND fecha_desembolso IS NOT NULL
