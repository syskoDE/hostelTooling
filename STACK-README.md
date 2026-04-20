# Hostel Tooling Stack

Dieses Verzeichnis enthaelt das lokale Betriebs-Setup fuer den Vector- und Observability-Teil von Hostel.

Ziel:

- Qdrant lokal und reproduzierbar starten
- Metriken fuer den Vector Store bereitstellen
- optional Logs und Traces fuer spaetere produktionsnahe Tests aktivieren

Alle Befehle werden aus `hostelTooling` ausgefuehrt.

## Enthaltene Services

- `qdrant`: Vector Database fuer Embeddings und Retrieval
- `prometheus`: Metrik-Sammlung
- `grafana`: Dashboards und Datenquellen
- `cadvisor`: Container-Metriken
- `loki`: Log-Speicher, optional
- `promtail`: Log-Ingestion, optional
- `tempo`: Trace-Speicher, optional
- `otel-collector`: OpenTelemetry Collector, optional

## Schnellstart

Minimales Setup:

```bash
docker compose up -d
```

Mit Logs:

```bash
docker compose --profile logs up -d
```

Mit Tracing:

```bash
docker compose --profile tracing up -d
```

Alles zusammen:

```bash
docker compose --profile logs --profile tracing up -d
```

Stoppen:

```bash
docker compose down
```

## URLs

- Qdrant: `http://localhost:6333`
- Qdrant gRPC: `localhost:6334`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`
- cAdvisor: `http://localhost:8080`
- Loki: `http://localhost:3100`
- Tempo: `http://localhost:3200`

Grafana Default-Login:

- User: `admin`
- Passwort: `admin`

## Health und Checks

- Qdrant Readiness: `http://localhost:6333/readyz`
- Qdrant Metrics: `http://localhost:6333/metrics`

Container-Status:

```bash
docker compose ps
```

Logs eines Service:

```bash
docker compose logs -f qdrant
```

## Hinweise fuer Hostel

- Der Stack ist bewusst getrennt vom eigentlichen `hostel`-Applikationsrepo.
- `hostelTooling` soll die produktionsnahe Betriebsumgebung vorbereiten, nicht den Applikationscode enthalten.
- Fuer lokale Entwicklung kann Hostel weiter Chroma oder andere Stores nutzen; fuer produktionsnahes Setup ist Qdrant hier der vorgesehene Startpunkt.
