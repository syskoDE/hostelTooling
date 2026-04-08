# unicorn-tooling Helm Chart

Dieses Chart ist der erste Kubernetes-Einstieg fuer `unicornTooling`.

Der aktuelle Scope ist bewusst klein:

- `Qdrant`
- `Prometheus`
- `Grafana`

Fuer ein getrenntes menschliches Access-Frontend existiert bewusst ein separates Chart unter:

- [../open-webui](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/unicornTooling/helm/open-webui)

Nicht im ersten Wurf enthalten:

- `cAdvisor`
- `Promtail`
- `Loki`
- `Tempo`
- `OpenTelemetry Collector`

## Security Defaults

Das Chart ist bewusst auf einen internen EKS-Startpunkt ausgelegt:

- alle Services standardmaessig `ClusterIP`
- keine Ingress-Ressourcen im Default
- `ServiceAccount` pro Komponente
- `automountServiceAccountToken: false`
- eingeschraenkte Container-Security-Defaults
- `NetworkPolicy` fuer Ingress je Komponente

Wichtig:

- `Grafana`-Default-Passwort muss vor echtem Deployment ueberschrieben werden
- fuer EKS sollten Secrets spaeter ueber AWS Secrets Manager und IRSA/Pod Identity angebunden werden
- `Qdrant`, `Prometheus` und `Grafana` sollten nicht direkt oeffentlich exponiert werden

## Empfohlener Admin-Zugriff

Fuer den ersten EKS-Betrieb ist der empfohlene Weg fuer menschlichen Admin-Zugriff:

- kein oeffentlicher Ingress fuer `Qdrant`
- kein oeffentlicher Ingress fuer `Prometheus`
- kein oeffentlicher Ingress fuer `Grafana` im ersten Schritt
- stattdessen `kubectl port-forward`

Das ist bewusst der bevorzugte Startpunkt, weil:

- keine zusaetzliche oeffentliche Angriffsoberflaeche entsteht
- kein fruehes ALB-/Ingress-/TLS-Setup noetig ist
- der Zugriff nur temporaer und kontrolliert erfolgt

### Beispiele

Qdrant:

```bash
kubectl port-forward -n unicorn-tooling svc/unicorn-tooling-qdrant 6333:6333
```

Dann lokal erreichbar unter:

- `http://localhost:6333`

Prometheus:

```bash
kubectl port-forward -n unicorn-tooling svc/unicorn-tooling-prometheus 9090:9090
```

Dann lokal erreichbar unter:

- `http://localhost:9090`

Grafana:

```bash
kubectl port-forward -n unicorn-tooling svc/unicorn-tooling-grafana 3001:3000
```

Dann lokal erreichbar unter:

- `http://localhost:3001`

### Spaeterer Ausbau

Wenn spaeter regelmaessiger Team-Zugriff noetig wird, sind die naechsten sinnvollen Optionen:

- VPN
- Bastion Host
- gezielter interner Ingress fuer einzelne Oberflaechen

Fuer `Qdrant` bleibt die Empfehlung auch dann: moeglichst kein direkter oeffentlicher Internetzugang.

## Qdrant-Zugriff fuer Unicorn

Der Chart ist so vorbereitet, dass `Qdrant` spaeter gezielt fuer `unicorn`-Pods freigegeben werden kann, ohne den Service allgemein zu oeffnen.

### Erwartete Kopplung zum unicorn-Chart

Das aktuelle `unicorn`-Chart erwartet im Default:

- Namespace von `Qdrant`:
  `unicorn-tooling`
- Service-Name:
  `unicorn-tooling-qdrant`
- vollqualifizierter DNS-Name:
  `unicorn-tooling-qdrant.unicorn-tooling.svc.cluster.local`
- `unicorn`-Pod-Label:
  `app.kubernetes.io/name: unicorn`

Wenn ihr Release-Namen oder Namespaces aendert, muessen `unicorn/helm/unicorn/values*.yaml` und die `Qdrant`-Freigabe zusammen angepasst werden.

Die Freigabe erfolgt ueber Pod-Labels in:

- [values.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/unicornTooling/helm/unicorn-tooling/values.yaml)
- [values-eks.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/unicornTooling/helm/unicorn-tooling/values-eks.yaml)

Beispiel fuer `unicorn` im selben Namespace:

```yaml
qdrant:
  networkPolicy:
    allowFromWorkloads:
      - podSelector:
          matchLabels:
            app.kubernetes.io/name: unicorn
```

Beispiel fuer `unicorn` in einem anderen Namespace:

```yaml
qdrant:
  networkPolicy:
    allowFromWorkloads:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: unicorn
        podSelector:
          matchLabels:
            app.kubernetes.io/name: unicorn
```

Damit darf nur genau diese Workload auf `Qdrant` zugreifen, waehrend der Rest des Clusters weiterhin ausgeschlossen bleibt.

### Empfohlene Reihenfolge

1. `unicornTooling` deployen
2. `Qdrant`-Freigabe fuer `unicorn` per Override aktivieren
3. erst dann `unicorn` deployen

Praktisch ist es sinnvoll, die Freigabe in einer separaten Datei wie `values-unicorn-access.yaml` zu halten, damit klar bleibt, welche Runtime darauf zugreifen darf.

## Struktur

```text
helm/unicorn-tooling/
  Chart.yaml
  values.yaml
  templates/
```

## Installation

```bash
cd unicornTooling
helm upgrade --install unicorn-tooling ./helm/unicorn-tooling -n unicorn-tooling --create-namespace

# Beispiel fuer EKS
helm upgrade --install unicorn-tooling ./helm/unicorn-tooling -n unicorn-tooling --create-namespace -f ./helm/unicorn-tooling/values-eks.yaml
```

## Rendering testen

```bash
helm template unicorn-tooling ./helm/unicorn-tooling
```

## Naechste sinnvolle Schritte

- Ingress fuer Grafana
- getrenntes Open WebUI Frontend bei Bedarf deployen
- Secrets ueber External Secrets oder Vault
- Loki/Tempo optional ergaenzen
- Community-Charts fuer Teilkomponenten evaluieren
