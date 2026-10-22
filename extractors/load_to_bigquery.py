import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from google.cloud import bigquery
from google.oauth2 import service_account

KEY_PATH = os.getenv("GCP_KEY_PATH", "gcp-credentials.json")
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "fintech-credit-analytics")
DATASET_ID = "raw_vault"
LOCATION = "US"

DATA_DIR = Path(__file__).resolve().parent / "data"

TABLAS_FUENTES = {
    "raw_clientes": "clientes.jsonl",
    "raw_solicitudes": "solicitudes_credito.jsonl",
    "raw_pagos": "pagos_cuotas.jsonl"
}

def obtener_cliente_bigquery():
    credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
    return bigquery.Client(credentials=credentials, project=PROJECT_ID)

def crear_dataset_si_no_existe(client):
    dataset_ref = bigquery.DatasetReference(PROJECT_ID, DATASET_ID)
    dataset = bigquery.Dataset(dataset_ref)
    dataset.location = LOCATION
    client.create_dataset(dataset, exists_ok=True)
    print(f"[✓] Dataset '{DATASET_ID}' verificado y listo.")

def cargar_tabla_cruda(client, nombre_tabla, archivo_jsonl):
    filepath = DATA_DIR / archivo_jsonl
    if not filepath.exists():
        print(f"[!] Error: No se encontró {filepath}. Ejecutá mock_fintech_generator.py primero.")
        return

    table_id = f"{PROJECT_ID}.{DATASET_ID}.{nombre_tabla}"

    schema = [
        bigquery.SchemaField("id_ingesta", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("ingested_at", "TIMESTAMP", mode="REQUIRED"),
        bigquery.SchemaField("source_system", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("payload_json", "STRING", mode="REQUIRED")
    ]

    print(f"[*] Leyendo y empaquetando {archivo_jsonl}...")
    rows_to_insert = []
    timestamp_actual = datetime.now(timezone.utc).isoformat()

    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                rows_to_insert.append({
                    "id_ingesta": str(uuid.uuid4()),
                    "ingested_at": timestamp_actual,
                    "source_system": "api_fintech_mock_v1",
                    "payload_json": line.strip()
                })

    print(f"[*] Ejecutando Load Job batch de {len(rows_to_insert)} registros en {table_id}...")

    # Configuración de Load Job (compatible 100% con Free Tier Sandbox)
    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE
    )

    job = client.load_table_from_json(rows_to_insert, table_id, job_config=job_config)
    job.result()  # Espera a que termine la carga batch

    print(f"[✓] Carga completada en {table_id} ({job.output_rows} filas persistidas).")

if __name__ == "__main__":
    client = obtener_cliente_bigquery()
    crear_dataset_si_no_existe(client)

    for tabla, archivo in TABLAS_FUENTES.items():
        cargar_tabla_cruda(client, tabla, archivo)

    print("\n[OK] Fase 1 finalizada: Capa Bronze disponible en BigQuery.")
