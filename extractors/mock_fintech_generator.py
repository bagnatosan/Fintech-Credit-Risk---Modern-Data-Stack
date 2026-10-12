import json
import random
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path
from faker import Faker

fake = Faker('es_AR')
random.seed(42)

OUTPUT_DIR = Path(__file__).resolve().parent / "data"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

PROVINCIAS = [
    'Buenos Aires', 'CABA', 'Córdoba', 'Santa Fe', 'Mendoza',
    'Tucumán', 'Salta', 'Entre Ríos', 'Neuquén', 'Chaco'
]
CANALES_VALIDOS = [1, 2, 3, 4]  # 1: App Mobile, 2: Web, 3: Sucursal, 4: Alianzas Comerciales
PLAZOS = [6, 12, 18, 24, 36]

def generar_clientes(total_base=3000, porcentaje_scd2=0.10):
    clientes_records = []
    clientes_para_actualizar = []

    start_date = date(2024, 1, 1)
    end_date = date(2025, 6, 30)

    print(f"[*] Generando {total_base} clientes base...")
    for cliente_id in range(1, total_base + 1):
        fecha_alta = fake.date_between(start_date=start_date, end_date=end_date)
        score = random.randint(350, 850)
        ingresos = round(random.uniform(400000, 3500000), 2)

        record_v1 = {
            "id_cliente": cliente_id,
            "nombre": fake.first_name(),
            "apellido": fake.last_name(),
            "email": fake.email(),
            "provincia": random.choice(PROVINCIAS),
            "ingresos_mensuales": ingresos,
            "score_bancario": score,
            "updated_at": datetime.combine(fecha_alta, datetime.min.time()).isoformat()
        }
        clientes_records.append(record_v1)

        # Seleccionar muestra para evolución histórica (SCD Tipo 2)
        if random.random() < porcentaje_scd2:
            clientes_para_actualizar.append(record_v1)

    print(f"[*] Generando {len(clientes_para_actualizar)} eventos de actualización SCD2 para clientes...")
    for cl in clientes_para_actualizar:
        fecha_v1 = datetime.fromisoformat(cl["updated_at"]).date()
        fecha_v2 = fake.date_between(start_date=fecha_v1 + timedelta(days=60), end_date=date(2026, 9, 30))
        
        # Variación de ingresos y score
        nuevo_score = max(300, min(850, cl["score_bancario"] + random.randint(-120, 150)))
        nuevos_ingresos = round(cl["ingresos_mensuales"] * random.uniform(0.85, 1.45), 2)

        record_v2 = {
            "id_cliente": cl["id_cliente"],
            "nombre": cl["nombre"],
            "apellido": cl["apellido"],
            "email": cl["email"],
            "provincia": cl["provincia"],
            "ingresos_mensuales": nuevos_ingresos,
            "score_bancario": nuevo_score,
            "updated_at": datetime.combine(fecha_v2, datetime.min.time()).isoformat()
        }
        clientes_records.append(record_v2)

    return clientes_records


def generar_solicitudes_y_pagos(clientes, total_solicitudes=8000):
    solicitudes = []
    pagos = []
    clientes_ids = list({c["id_cliente"] for c in clientes})

    print(f"[*] Generando {total_solicitudes} solicitudes de préstamo y sus cuotas...")
    pago_id_seq = 1

    for solicitud_id in range(1, total_solicitudes + 1):
        cliente_id = random.choice(clientes_ids)
        canal = random.choice(CANALES_VALIDOS)
        plazo = random.choice(PLAZOS)
        
        monto_solicitado = round(random.uniform(200000, 5000000), -3)
        # 85% de aprobación
        es_aprobado = random.random() < 0.85
        
        monto_otorgado = monto_solicitado if es_aprobado else 0.0
        tasa = round(random.uniform(0.55, 1.35), 4) if es_aprobado else 0.0
        
        fecha_desembolso = fake.date_between(start_date=date(2025, 1, 1), end_date=date(2026, 8, 31))
        
        estado = "APROBADO" if es_aprobado else "RECHAZADO"

        solicitud_record = {
            "id_solicitud": solicitud_id,
            "id_cliente": cliente_id,
            "id_canal": canal,
            "monto_solicitado": monto_solicitado,
            "monto_otorgado": monto_otorgado,
            "tasa_nominal_anual": tasa,
            "plazo_meses": plazo,
            "fecha_desembolso": fecha_desembolso.isoformat() if es_aprobado else None,
            "estado": estado,
            "created_at": datetime.combine(fecha_desembolso, datetime.min.time()).isoformat()
        }
        solicitudes.append(solicitud_record)

        # Generar cuotas solo para aprobados
        if es_aprobado:
            # Cuota fija simple: (Capital / Plazo) + Interés mensual
            interes_mensual = (monto_otorgado * (tasa / 12))
            cuota_capital = monto_otorgado / plazo
            monto_cuota = round(cuota_capital + interes_mensual, 2)

            fecha_corte_simulada = date(2026, 10, 1)

            for nro_cuota in range(1, plazo + 1):
                # Vencimiento mensual aproximado cada 30 días
                vencimiento = fecha_desembolso + timedelta(days=30 * nro_cuota)

                # Si el vencimiento ya pasó respecto a la fecha actual simulada
                if vencimiento <= fecha_corte_simulada:
                    # Comportamiento de pago según probabilidad
                    prob_pago = random.random()
                    if prob_pago < 0.82:
                        # Pagado a tiempo o leve atraso
                        dias_mora = max(0, random.choice([0, 0, 0, 2, 5, 12]))
                        fecha_pago = vencimiento + timedelta(days=dias_mora)
                        estado_pago = "PAGADO"
                    elif prob_pago < 0.94:
                        # Mora abierta (impago temporal)
                        dias_mora = (fecha_corte_simulada - vencimiento).days
                        fecha_pago = None
                        estado_pago = "MORA"
                    else:
                        # Incobrable severo
                        dias_mora = (fecha_corte_simulada - vencimiento).days
                        fecha_pago = None
                        estado_pago = "DEFAULT"
                else:
                    # Cuota a futuro
                    dias_mora = 0
                    fecha_pago = None
                    estado_pago = "PENDIENTE"

                pago_record = {
                    "id_pago": pago_id_seq,
                    "id_solicitud": solicitud_id,
                    "numero_cuota": nro_cuota,
                    "fecha_vencimiento": vencimiento.isoformat(),
                    "fecha_pago_real": fecha_pago.isoformat() if fecha_pago else None,
                    "monto_cuota": monto_cuota,
                    "dias_mora": dias_mora,
                    "estado_pago": estado_pago
                }
                pagos.append(pago_record)
                pago_id_seq += 1

    # --- INYECCIÓN DELIBERADA DE ANOMALÍAS ---
    print("[!] Inyectando anomalías controladas para testing de dbt y EDA...")
    
    # 1. Cinco tasas de interés negativas
    for idx in range(5):
        solicitudes[idx]["tasa_nominal_anual"] = -0.15

    # 2. Ocho canales inexistentes (id_canal = 999) para probar huérfanos
    for idx in range(5, 13):
        solicitudes[idx]["id_canal"] = 999

    return solicitudes, pagos


def guardar_jsonl(datos, filename):
    filepath = OUTPUT_DIR / filename
    with open(filepath, "w", encoding="utf-8") as f:
        for r in datos:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"[✓] Guardado: {filepath} ({len(datos)} registros)")


if __name__ == "__main__":
    clientes = generar_clientes()
    solicitudes, pagos = generar_solicitudes_y_pagos(clientes)

    guardar_jsonl(clientes, "clientes.jsonl")
    guardar_jsonl(solicitudes, "solicitudes_credito.jsonl")
    guardar_jsonl(pagos, "pagos_cuotas.jsonl")
    print("\n[OK] Generación sintética finalizada exitosamente.")