/*
	Regla de negocio: Toda cuota registrada bajo el estado 'PAGADO' debe contar obligatoriamente 
  con su marca de tiempo efectiva ('fecha_pago_real'). 
*/

SELECT id_pago, id_solicitud, estado_pago, fecha_pago_real
FROM {{ ref('stg_pagos') }}
WHERE estado_pago = 'PAGADO'
AND fecha_pago_real IS NULL
