# unicornTooling

`unicornTooling` enthaelt die Betriebs- und Infrastruktur-Bausteine, um `unicorn` produktionsnah laufen zu lassen.

Der Fokus liegt hier nicht auf dem Python-Applikationscode, sondern auf den Systemen drumherum:

- Vector Store
- Monitoring
- Logging
- Tracing
- spaetere weitere Runtime- und Ops-Setups

## Enthaltene Services

Der aktuelle Root-Stack in `unicornTooling` stellt bereit:

- Qdrant als Vector Database
- Prometheus fuer Metriken
- Grafana fuer Dashboards
- cAdvisor fuer Container-Metriken
- optional Loki/Promtail fuer Logs
- optional Tempo/OpenTelemetry Collector fuer Tracing

## Schnellstart

1. In das Tooling-Verzeichnis wechseln:

```bash
cd unicornTooling
```

2. Minimalen Stack starten:

```bash
docker compose up -d
```

3. Optional Logs und Tracing aktivieren:

```bash
docker compose --profile logs --profile tracing up -d
```

4. Verfuegbarkeit pruefen:

- Qdrant: `http://localhost:6333/readyz`
- Grafana: `http://localhost:3001`
- Prometheus: `http://localhost:9090`

## Empfohlene Nutzung mit `unicorn`

`unicornTooling` und `unicorn` sind bewusst getrennt:

- `unicorn` enthaelt die Applikation, Agentenlogik und RAG-/Tool-Integration
- `unicornTooling` enthaelt die begleitenden Systeme fuer einen produktionsnahen Betrieb

Empfohlener Start:

1. Vector- und Observability-Stack in `unicornTooling` starten
2. Danach `unicorn` mit passender Vector-Store-Konfiguration gegen Qdrant betreiben
3. Metriken, Logs und spaeter Traces ueber die bereitgestellten Tools beobachten

## Weitere Doku

- [STACK-README.md](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/unicornTooling/STACK-README.md)

## Naechste sinnvolle Ausbaustufen

- separates Deployment fuer Unicorn Runtime
- Secret-Management und Environment-Templates
- Reverse Proxy / TLS
- Backup- und Restore-Strategien fuer Qdrant
- produktionsnahe Grafana-Dashboards
