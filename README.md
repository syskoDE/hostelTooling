# hostelTooling

`hostelTooling` enthaelt die Betriebs- und Infrastruktur-Bausteine, um `hostel` produktionsnah laufen zu lassen.

Der Fokus liegt hier nicht auf dem Python-Applikationscode, sondern auf den Systemen drumherum:

- Vector Store
- Monitoring
- Logging
- Tracing
- spaetere weitere Runtime- und Ops-Setups

## Enthaltene Services

Der aktuelle Root-Stack in `hostelTooling` stellt bereit:

- Qdrant als Vector Database
- Prometheus fuer Metriken
- Grafana fuer Dashboards
- cAdvisor fuer Container-Metriken
- optional Loki/Promtail fuer Logs
- optional Tempo/OpenTelemetry Collector fuer Tracing

## Schnellstart

1. In das Tooling-Verzeichnis wechseln:

```bash
cd hostelTooling
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

## Empfohlene Nutzung mit `hostel`

`hostelTooling` und `hostel` sind bewusst getrennt:

- `hostel` enthaelt die Applikation, Agentenlogik und RAG-/Tool-Integration
- `hostelTooling` enthaelt die begleitenden Systeme fuer einen produktionsnahen Betrieb

Empfohlener Start:

1. Vector- und Observability-Stack in `hostelTooling` starten
2. Danach `hostel` mit passender Vector-Store-Konfiguration gegen Qdrant betreiben
3. Metriken, Logs und spaeter Traces ueber die bereitgestellten Tools beobachten

## Weitere Doku

- [STACK-README.md](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/STACK-README.md)
- [Helm Chart README](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/hostel-tooling/README.md)
- [Open WebUI Helm Wrapper](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/open-webui/README.md)

## Kubernetes

Ein erster Helm-Chart fuer den K8s-Einstieg liegt unter:

- [helm/hostel-tooling](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/hostel-tooling)
- [helm/open-webui](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/open-webui) fuer das getrennte interne Access-Frontend

Beispiel:

```bash
cd hostelTooling
helm upgrade --install hostel-tooling ./helm/hostel-tooling -n hostel-tooling --create-namespace
```

## Naechste sinnvolle Ausbaustufen

- separates Deployment fuer Hostel Runtime
- separates Access-Frontend fuer menschliche Nutzer per Open WebUI
- Secret-Management und Environment-Templates
- Reverse Proxy / TLS
- Backup- und Restore-Strategien fuer Qdrant
- produktionsnahe Grafana-Dashboards
