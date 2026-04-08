# Open WebUI Helm Wrapper

Dieses Chart fuehrt `Open WebUI` als internes Access-Frontend fuer `unicorn` ein.

Der Scope ist bewusst klar getrennt:

- `unicornTooling/helm/unicorn-tooling` bleibt Infra-/Ops-Chart fuer Qdrant, Prometheus und Grafana
- `unicornTooling/helm/open-webui` ist ein separates Access-Frontend fuer menschliche Nutzer
- `unicorn` bleibt das eigentliche Agenten-Backend und wird nur ueber seine OpenAI-kompatible API angesprochen

## Architektur

- Namespace: `unicorn-access`
- Release: `open-webui`
- Ingress: interner AWS ALB
- Authentifizierung: OIDC gegen Entra ID
- Backend fuer Modelle/Chats: `http://unicorn.unicorn.svc.cluster.local:8000/v1`
- keine direkte Verbindung von `Open WebUI` zu `Qdrant`

## Voraussetzungen

- `unicorn` ist im Namespace `unicorn` deployt
- `unicorn` ist ueber den Service `unicorn` intern erreichbar
- die `unicorn`-NetworkPolicy erlaubt Zugriff aus `unicorn-access`
- AWS Load Balancer Controller ist im Cluster vorhanden
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

Das Chart erwartet ein bestehendes Secret `open-webui-runtime` im Namespace `unicorn-access`.

Beispiel:

```bash
kubectl create namespace unicorn-access

kubectl create secret generic open-webui-runtime \
  -n unicorn-access \
  --from-literal=webui-secret-key='<stable-random-secret>' \
  --from-literal=oidc-client-secret='<entra-client-secret>' \
  --from-literal=openai-api-key='placeholder-not-validated-by-unicorn-yet'
```

Hinweise:

- `webui-secret-key` muss stabil bleiben, sonst brechen Sessions bei Pod-Neustarts
- `openai-api-key` ist aktuell nur ein Platzhalter, weil `unicorn` die interne OpenAI-kompatible API noch nicht per API-Key schuetzt

## Deployment

Zuerst sicherstellen, dass `unicorn` den Zugriff aus `unicorn-access` erlaubt.
Die passende Beispiel-Freigabe liegt in:

- [unicorn/helm/unicorn/values-eks.yaml](/Users/t.bettmann/Documents/dev/Agents/SDLC-Design/unicorn/helm/unicorn/values-eks.yaml)

Danach:

```bash
cd /Users/t.bettmann/Documents/dev/Agents/SDLC-Design
helm upgrade --install open-webui ./unicornTooling/helm/open-webui \
  -n unicorn-access \
  --create-namespace \
  -f ./unicornTooling/helm/open-webui/values-eks.yaml
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
- Modelle aus `unicorn` erscheinen in der Modellliste
- Chats funktionieren gegen einen vorhandenen `unicorn`-Agenten
