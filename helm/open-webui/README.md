# Open WebUI Helm Wrapper

Dieses Chart fuehrt `Open WebUI` als internes Access-Frontend fuer `hostel` ein.

Hinweis fuer das aktuelle Azure-Setup:

- die operative Referenz liegt in
  [k8s_Deployment/Azure/operations-runbook.md](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/k8s_Deployment/Azure/operations-runbook.md)
- produktiv laeuft Open WebUI aktuell auf AKS mit:
  - Host `chat.syskoplan.cloud`
  - AKS App Routing
  - cert-manager + Route53
  - Entra ID OIDC
  - Azure Key Vault + External Secrets fuer `open-webui-runtime`

Versionshinweis:

- der vendorte Helm-Chart-Wrapper bleibt bewusst schlank und kann bei der
  `appVersion` hinter dem jeweils gewuenschten Runtime-Image hinterherlaufen
- produktiv pinnen wir das Open-WebUI-Image deshalb explizit ueber
  `open-webui.image.tag`
- aktueller Sollstand: `v0.9.1`

Der Scope ist bewusst klar getrennt:

- `hostelTooling/helm/hostel-tooling` bleibt Infra-/Ops-Chart fuer Qdrant, Prometheus und Grafana
- `hostelTooling/helm/open-webui` ist ein separates Access-Frontend fuer menschliche Nutzer
- `hostel` bleibt das eigentliche Agenten-Backend und wird nur ueber seine OpenAI-kompatible API angesprochen

## Architektur

- Namespace: `hostel-access`
- Release: `open-webui`
- Ingress: interner AWS ALB
- Authentifizierung: OIDC gegen Entra ID
- gemeinsame Frontend-Instanz fuer mehrere Projekt-Backends
- initialer Bootstrap-Backend-Eintrag im Chart: `http://hostel-mvv.hostel-mvv.svc.cluster.local:8000/v1`
- weitere OpenAI-kompatible Connections werden nach dem Deploy in der Admin-UI gepflegt
- keine direkte Verbindung von `Open WebUI` zu `Qdrant`

## Voraussetzungen

- `hostel-mvv` ist im Namespace `hostel-mvv` deployt
- `hostel-admin` ist im Namespace `hostel-admin` deployt
- beide Backends sind ueber ihre Services intern erreichbar
- die NetworkPolicies von `hostel-mvv` und `hostel-admin` erlauben Zugriff aus `hostel-access`
- ein internes DNS-/Zertifikats-Setup fuer `chat.<interne-domain>` existiert
- eine Entra-ID-App fuer OIDC ist registriert

Fuer jeden eingebundenen `hostel`-Pfad muss die NetworkPolicy des Backends
Ingress aus `hostel-access` fuer die Open-WebUI-Pods explizit erlauben. Ohne
diese Freigabe bekommt Open WebUI bei `/api/models` fuer das jeweilige Backend
Timeout-/Connection-Fehler, obwohl die Connection-URL korrekt gesetzt ist.

## Entra ID / OIDC

In Entra ID eine Web-Anwendung anlegen und als Redirect URI exakt eintragen:

- `https://chat.<interne-domain>/oauth/oidc/callback`

Im Chart muessen dann mindestens diese Platzhalter ersetzt werden:

- `open-webui.ingress.host`
- `alb.ingress.kubernetes.io/certificate-arn`
- `open-webui.sso.oidc.clientId`
- `open-webui.sso.oidc.providerUrl`
- `WEBUI_URL`
- `OPENID_REDIRECT_URI`

Empfohlener OIDC-Provider-URL-Schnitt fuer Entra ID:

- `https://login.microsoftonline.com/<tenant-id>/v2.0/.well-known/openid-configuration`

Fuer die projektbezogene Modelltrennung ist im aktuellen Zielbild ausserdem
gewollt:

- OIDC Group Management in Open WebUI aktiv
- automatische Synchronisation von Entra-Gruppen
- Gruppenclaim `groups`
- projektbezogene Gruppen wie `project-mvv` und `project-admin`

## Runtime-Secret

Das Chart erwartet ein bestehendes Secret `open-webui-runtime` im Namespace `hostel-access`.

Beispiel:

```bash
kubectl create namespace hostel-access

kubectl create secret generic open-webui-runtime \
  -n hostel-access \
  --from-literal=webui-secret-key='<stable-random-secret>' \
  --from-literal=oidc-client-secret='<entra-client-secret>' \
  --from-literal=openai-api-key='placeholder-not-validated-by-hostel-yet'
```

Hinweise:

- `webui-secret-key` muss stabil bleiben, sonst brechen Sessions bei Pod-Neustarts
- `openai-api-key` ist aktuell nur ein Platzhalter, weil `hostel` die interne OpenAI-kompatible API noch nicht per API-Key schuetzt

Fuer das aktuelle Azure-Cluster wird das Secret ueber External Secrets aus Key Vault synchronisiert:

- [k8s_Deployment/Azure/external-secrets/externalsecret-open-webui-runtime.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/k8s_Deployment/Azure/external-secrets/externalsecret-open-webui-runtime.yaml)

## Deployment

Zuerst sicherstellen, dass `hostel` den Zugriff aus `hostel-access` erlaubt.
Die passende Beispiel-Freigabe liegt in:

- [hostel/helm/hostel/values-aks.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/hostel/helm/hostel/values-aks.yaml)

Danach:

```bash
cd /Users/t.bettmann/Documents/dev/Agents/SDLC-Design
helm upgrade --install open-webui ./hostelTooling/helm/open-webui \
  -n hostel-access \
  --create-namespace \
  -f ./hostelTooling/helm/open-webui/values-aks-entra.yaml
```

Hinweis:

- die Upstream-Dependency ist bereits in `charts/` vendort
- `helm dependency update` ist nur noetig, wenn die Open-WebUI-Chart-Version bewusst aktualisiert werden soll
- das Helm-Chart hinterlegt nur den initialen Bootstrap-Pfad
- getrennte Projekt-Connections werden bewusst in der Admin-UI angelegt, weil
  Open WebUI mehrere URLs aus der Env-Konfiguration nicht als separat benannte
  Connections im UI modelliert

## Admin-Ersteinrichtung fuer mehrere Projekte

Nach dem technischen Deploy wird die Projekttrennung in Open WebUI bewusst ueber
die Admin-UI vervollstaendigt.

### 1. Connections anlegen

Unter `Admin Settings -> Connections -> OpenAI -> Manage`:

- die Bootstrap-Connection zu `hostel-mvv` pruefen oder neu anlegen
- fuer jede weitere `hostel`-Instanz eine eigene Connection anlegen
- fuer `hostel-admin` die URL `http://hostel-admin.hostel-admin.svc.cluster.local:8000/v1` verwenden
- fuer spaetere Projekte jeweils die interne Service-URL im Muster
  `http://hostel-<slug>.hostel-<slug>.svc.cluster.local:8000/v1` verwenden
- Prefixe manuell setzen:
  - `mvv/`
  - `admin/`

Wenn eine neue Projektinstanz hinzukommt, ist genau dieser Schritt zusaetzlich
zum Backend-Deploy noetig: Open WebUI kennt neue `hostel`-Instanzen nicht
automatisch, sondern erst nach dem Anlegen der Connection.

### 2. OIDC-Gruppen pruefen

- sicherstellen, dass Open WebUI Entra-Gruppen synchronisiert
- sicherstellen, dass der Claim `groups` im Token enthalten ist
- erwartete Gruppen:
  - `project-mvv`
  - `project-admin`
  - optional eine Betriebsgruppe mit Schreibrechten
- fuer die Verifikation einen Nicht-Admin-User verwenden, weil Open WebUI
  Admin-Gruppenmitgliedschaften nicht automatisch aktualisiert

### 3. Modelle freigeben

In der Modellverwaltung:

- MVV-Modelle auf `Private` oder `Restricted` setzen und fuer `project-mvv` freigeben
- Admin-Modelle auf `Private` oder `Restricted` setzen und fuer `project-admin` freigeben
- Schreibrechte nur an die benoetigten Betriebsgruppen vergeben

### 4. Sichtbarkeit testen

- Nutzer nur mit `project-mvv` sehen nur `mvv/*`
- Nutzer nur mit `project-admin` sehen nur `admin/*`
- Nutzer mit beiden Gruppen sehen beide Modellmengen

## Betriebsverhalten

- lokaler Login ist deaktiviert
- OIDC-Sign-up ist aktiviert
- der erste Account auf einer frischen Instanz wird Admin
- spaetere Nutzer landen standardmaessig als `pending` und muessen freigeschaltet werden
- OIDC-Gruppen koennen aus Entra synchronisiert werden und steuern die projektbezogene Modellsichtbarkeit
- `Open WebUI` nutzt das chart-eigene Redis fuer WebSockets
- v1 bleibt bewusst bei `replicaCount: 1` und lokaler PVC-Persistenz

## Validierung

Nach dem Deploy sollten mindestens diese Punkte funktionieren:

- ALB/Ingress zeigt auf `https://chat.<interne-domain>`
- Login fuehrt zu Entra ID weiter
- Callback nach `.../oauth/oidc/callback` funktioniert
- Connections zu `hostel-mvv` und `hostel-admin` lassen sich speichern
- Modelle aus beiden Backends erscheinen mit ihren Prefixen in der Modellliste
- Gruppenbasierte Modellfreigaben filtern die Sichtbarkeit wie erwartet
- Chats funktionieren gegen einen vorhandenen `hostel-mvv`- und `hostel-admin`-Agenten
