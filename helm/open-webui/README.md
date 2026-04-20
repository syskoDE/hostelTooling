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

Der Scope ist bewusst klar getrennt:

- `hostelTooling/helm/hostel-tooling` bleibt Infra-/Ops-Chart fuer Qdrant, Prometheus und Grafana
- `hostelTooling/helm/open-webui` ist ein separates Access-Frontend fuer menschliche Nutzer
- `hostel` bleibt das eigentliche Agenten-Backend und wird nur ueber seine OpenAI-kompatible API angesprochen

## Architektur

- Namespace: `hostel-access`
- Release: `open-webui`
- Ingress: interner AWS ALB
- Authentifizierung: OIDC gegen Entra ID
- Backend fuer Modelle/Chats: `http://hostel.hostel.svc.cluster.local:8000/v1`
- keine direkte Verbindung von `Open WebUI` zu `Qdrant`

## Voraussetzungen

- `hostel` ist im Namespace `hostel` deployt
- `hostel` ist ueber den Service `hostel` intern erreichbar
- die `hostel`-NetworkPolicy erlaubt Zugriff aus `hostel-access`
- ein internes DNS-/Zertifikats-Setup fuer `chat.<interne-domain>` existiert
- eine Entra-ID-App fuer OIDC ist registriert

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
  -f ./hostelTooling/helm/open-webui/values-aks.yaml
```

Hinweis:

- die Upstream-Dependency ist bereits in `charts/` vendort
- `helm dependency update` ist nur noetig, wenn die Open-WebUI-Chart-Version bewusst aktualisiert werden soll

## Betriebsverhalten

- lokaler Login ist deaktiviert
- OIDC-Sign-up ist aktiviert
- der erste Account auf einer frischen Instanz wird Admin
- spaetere Nutzer landen standardmaessig als `pending` und muessen freigeschaltet werden
- `Open WebUI` nutzt das chart-eigene Redis fuer WebSockets
- v1 bleibt bewusst bei `replicaCount: 1` und lokaler PVC-Persistenz

## Validierung

Nach dem Deploy sollten mindestens diese Punkte funktionieren:

- ALB/Ingress zeigt auf `https://chat.<interne-domain>`
- Login fuehrt zu Entra ID weiter
- Callback nach `.../oauth/oidc/callback` funktioniert
- Modelle aus `hostel` erscheinen in der Modellliste
- Chats funktionieren gegen einen vorhandenen `hostel`-Agenten
