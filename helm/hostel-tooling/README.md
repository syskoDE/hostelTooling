# hostel-tooling Helm Chart

Dieses Chart ist der erste Kubernetes-Einstieg fuer `hostelTooling`.

Der aktuelle Scope ist bewusst klein:

- `Qdrant`
- `Prometheus`
- `Grafana`

Fuer ein getrenntes menschliches Access-Frontend existiert bewusst ein separates Chart unter:

- [../open-webui](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/open-webui)

Nicht im ersten Wurf enthalten:

- `cAdvisor`
- `Promtail`
- `Loki`
- `Tempo`
- `OpenTelemetry Collector`
- `kube-state-metrics` im Default-Install

## Security Defaults

Das Chart ist bewusst auf einen internen EKS-Startpunkt ausgelegt:

- alle Services standardmaessig `ClusterIP`
- keine Ingress-Ressourcen im Default
- `ServiceAccount` pro Komponente
- `automountServiceAccountToken: false`
- eingeschraenkte Container-Security-Defaults
- `NetworkPolicy` fuer Ingress je Komponente

Wichtig:

- `Grafana`-Admin-Zugang sollte vor echtem Deployment ueber ein bestehendes Secret oder mindestens per Override gesetzt werden
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
kubectl port-forward -n hostel-tooling svc/hostel-tooling-qdrant 6333:6333
```

Dann lokal erreichbar unter:

- `http://localhost:6333`

Prometheus:

```bash
kubectl port-forward -n hostel-tooling svc/hostel-tooling-prometheus 9090:9090
```

Dann lokal erreichbar unter:

- `http://localhost:9090`

Grafana:

```bash
kubectl port-forward -n hostel-tooling svc/hostel-tooling-grafana 3001:3000
```

Dann lokal erreichbar unter:

- `http://localhost:3001`

### Spaeterer Ausbau

Wenn spaeter regelmaessiger Team-Zugriff noetig wird, sind die naechsten sinnvollen Optionen:

- VPN
- Bastion Host
- gezielter interner Ingress fuer einzelne Oberflaechen

Fuer `Qdrant` bleibt die Empfehlung auch dann: moeglichst kein direkter oeffentlicher Internetzugang.

## Qdrant-Zugriff fuer Hostel

Der Chart ist so vorbereitet, dass `Qdrant` spaeter gezielt fuer `hostel`-Pods freigegeben werden kann, ohne den Service allgemein zu oeffnen.

### Erwartete Kopplung zum hostel-Chart

Das aktuelle `hostel`-Chart erwartet im Default:

- Namespace von `Qdrant`:
  `hostel-tooling`
- Service-Name:
  `hostel-tooling-qdrant`
- vollqualifizierter DNS-Name:
  `hostel-tooling-qdrant.hostel-tooling.svc.cluster.local`
- `hostel`-Pod-Label:
  `app.kubernetes.io/name: hostel`

Wenn ihr Release-Namen oder Namespaces aendert, muessen `hostel/helm/hostel/values*.yaml` und die `Qdrant`-Freigabe zusammen angepasst werden.

Wichtig:
- Fuer jeden zusaetzlichen `hostel`-Namespace braucht `Qdrant` einen eigenen `allowFromWorkloads`-Eintrag.
- Ein neues Projekt wie `hostel-mvv` funktioniert also nicht automatisch nur deshalb, weil `hostel` bereits freigeschaltet wurde.
- Wenn diese Freigabe fehlt, zeigt sich das typischerweise als `ConnectTimeout` beim Zugriff von `hostel` auf `Qdrant`.

Die Freigabe erfolgt ueber Pod-Labels in:

- [values.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/hostel-tooling/values.yaml)
- [values-eks.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/hostel-tooling/values-eks.yaml)

Beispiel fuer `hostel` im selben Namespace:

```yaml
qdrant:
  networkPolicy:
    allowFromWorkloads:
      - podSelector:
          matchLabels:
            app.kubernetes.io/name: hostel
```

Beispiel fuer `hostel` in einem anderen Namespace:

```yaml
qdrant:
  networkPolicy:
    allowFromWorkloads:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: hostel
        podSelector:
          matchLabels:
            app.kubernetes.io/name: hostel
```

Beispiel fuer mehrere getrennte `hostel`-Namespaces:

```yaml
qdrant:
  networkPolicy:
    allowFromWorkloads:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: hostel
        podSelector:
          matchLabels:
            app.kubernetes.io/name: hostel
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: hostel-mvv
        podSelector:
          matchLabels:
            app.kubernetes.io/name: hostel
```

Damit darf nur genau diese Workload auf `Qdrant` zugreifen, waehrend der Rest des Clusters weiterhin ausgeschlossen bleibt.

### Empfohlene Reihenfolge

1. `hostelTooling` deployen
2. `Qdrant`-Freigabe fuer `hostel` per Override aktivieren
3. erst dann `hostel` deployen

Praktisch ist es sinnvoll, die Freigabe in einer separaten Datei wie `values-hostel-access.yaml` zu halten, damit klar bleibt, welche Runtime darauf zugreifen darf.

Bei jedem neuen `hostel`-Deployment sollte diese Datei bewusst mitgepflegt werden.

## Struktur

```text
helm/hostel-tooling/
  Chart.yaml
  values.yaml
  templates/
```

## Installation

```bash
cd hostelTooling
helm upgrade --install hostel-tooling ./helm/hostel-tooling -n hostel-tooling --create-namespace

# Beispiel fuer EKS
helm upgrade --install hostel-tooling ./helm/hostel-tooling -n hostel-tooling --create-namespace -f ./helm/hostel-tooling/values-eks.yaml
```

### Grafana Admin Secret

Fuer produktionsnahe Deployments sollte das Grafana-Passwort nicht direkt in den Values stehen.
Das Chart kann stattdessen ein bestehendes Secret referenzieren.

Beispiel:

Klassischer manueller Weg:

```bash
kubectl create secret generic hostel-tooling-grafana-admin \
  -n hostel-tooling \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password='<starkes-passwort>'
```

Fuer das aktuelle Azure-Setup ist zusaetzlich ein vorbereiteter External-Secrets-Pfad vorhanden:

- [k8s_Deployment/Azure/external-secrets/externalsecret-hostel-tooling-grafana-admin.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/k8s_Deployment/Azure/external-secrets/externalsecret-hostel-tooling-grafana-admin.yaml)
- erwartete Key-Vault-Secrets:
  - `hostel-tooling-grafana-admin-user`
  - `hostel-tooling-grafana-admin-password`

Passendes Override:

```yaml
grafana:
  admin:
    existingSecret: hostel-tooling-grafana-admin
    userKey: admin-user
    passwordKey: admin-password
```

## Rendering testen

```bash
helm template hostel-tooling ./helm/hostel-tooling
```

## Naechste sinnvolle Schritte

- Ingress fuer Grafana
- getrenntes Open WebUI Frontend bei Bedarf deployen
- Secrets ueber External Secrets oder Vault
- Loki/Tempo optional ergaenzen
- Community-Charts fuer Teilkomponenten evaluieren

## Minimales Alerting ueber kube-state-metrics

Das Chart ist darauf vorbereitet, zusaetzlich `kube-state-metrics` zu scrapen und erste Workload-Alerts in Prometheus auszuwerten.

Fuer AKS ist dieser Pfad in [values-aks.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostelTooling/helm/hostel-tooling/values-aks.yaml) aktiviert.

Der empfohlene Ablauf ist:

```bash
./k8s_Deployment/Azure/scripts/install-kube-state-metrics.sh

helm upgrade --install hostel-tooling ./hostelTooling/helm/hostel-tooling \
  -n hostel-tooling \
  --create-namespace \
  -f ./hostelTooling/helm/hostel-tooling/values-aks.yaml
```

Danach sind erste Alerts fuer diese Haupt-Workloads vorbereitet:

- `hostel`
- `open-webui`
- `sonarqube`
- `gitlab-runner`
