## Plan: CrowdSec for Docker Swarm + Traefik

Integrate CrowdSec (detect + block) into the Docker Swarm Traefik deployment using a forwardAuth bouncer pattern, with log acquisition via socket-proxy.

### Architecture

```
Internet → Traefik (port 443)
               │
               ├── forwardAuth middleware → traefik-bouncer → CrowdSec LAPI
               │                                            (decisions DB)
               │
               └── router → service (if allowed)

CrowdSec LAPI reads Traefik logs via Docker API → socket-proxy → Docker socket
```

All HTTPS traffic passes through the bouncer; the bouncer checks each request's IP against LAPI decisions. Non-HTTP entrypoints (smtp, mqtt, etc.) are not affected.

### Steps

#### Phase A — Rewrite `swarm/crowdsec.yml` for Swarm

1. **Convert CrowdSec LAPI service** to Swarm format:
   - Remove `restart: always`, `depends_on`, `container_name` (unsupported in Swarm)
   - Replace with `deploy:` block: `restart_policy` (condition: any), no placement constraint (can run on any manager/worker)
   - Change network to `overlay` (name: `crowdsec-internal`, attachable: true)
   - Change `COLLECTIONS: "crowdsecurity/nginx"` → `"crowdsecurity/traefik"`
   - Remove host port binding (`127.0.0.1:8080:8080`) — LAPI only needs to be reachable internally by the bouncer
   - Change bind mount `./crowdsec/acquis.yaml:...` to absolute host path `/var/data/crowdsec/acquis.yaml:/etc/crowdsec/acquis.yaml`
   - Add `CUSTOM_CS_LAPI_KEY=${CROWDSEC_LAPI_KEY:?Variable not set}` env var for deterministic API key
   - Keep named volumes `crowdsec-db` and `crowdsec-config` (Swarm supports named volumes)

2. **Add `traefik-bouncer` service** in the same stack:
   - Image: `crowdsecurity/traefik-bouncer:latest`
   - Environment:
     - `CROWDSEC_LAPI_URL=http://crowdsec:8080`
     - `CROWDSEC_LAPI_KEY=${CROWDSEC_BOUNCER_KEY:?Variable not set}`
   - Expose port `8080` internally (no `mode: host`, just internal for overlay routing)
   - Network: `crowdsec-internal` + `traefik-public` (so Traefik can reach it)
   - Deploy: `restart_policy` (condition: any)

3. **Adapt socket-proxy service** for Swarm:
   - Remove `container_name`, `restart: always`
   - Add `deploy:` block
   - Add `networks: [crowdsec-internal]`
   - Set `SWARM: 1` in socket-proxy env (was `SWARM: 0`) so it handles Swarm Docker API calls
   - Keep current limited permissions (CONTAINERS: 1, etc.)

4. **Network definitions:**
   - `crowdsec-internal`: driver `overlay`, attachable: true (for LAPI ↔ bouncer ↔ socket-proxy)
   - `traefik-public`: external: true (reuse existing)

#### Phase B — Update `swarm/core.yml` (Traefik config)

5. **Add crowdsec-bouncer middleware definition** to Traefik labels in core.yml:
   ```
   - traefik.http.middlewares.crowdsec-bouncer.forwardauth.address=http://traefik-bouncer:8080/api/v1/forwardAuth
   - traefik.http.middlewares.crowdsec-bouncer.forwardauth.trustForwardHeader=true
   ```

6. **Apply middleware to HTTPS entrypoint** — add to Traefik command args:
   ```
   - --entrypoints.https.http.middlewares=crowdsec-bouncer@swarm
   ```
   This applies globally to ALL HTTPS routers (dashboard + all services).

7. **Remove or update the old commented-out crowdsec labels:**
   ```
   # - crowdsec.enable=true
   # - crowdsec.labels.type=nginx
   ```
   Replace with a comment explaining the forwardAuth approach.

#### Phase C — Config files

8. **Create `/var/data/crowdsec/` config directory** (documented, can be a setup make target):
   - `acquis.yaml` already exists at `swarm/crowdsec/acquis.yaml` — it uses `source: docker` and `use_container_labels: true` which is correct for Traefik log acquisition
   - Add Traefik container label expectations as comments in acquis.yaml (Traefik needs label `crowdsec.enable=true`)
   - No additional parser config needed — `crowdsecurity/traefik` collection includes the Traefik parser

9. **Create `swarm/traefik/crowdsec-middleware.yml`** (optional file-provider config):
   - Alternative location to define the forwardAuth middleware if we want to keep core.yml clean
   - But defining on Traefik's own labels in core.yml is simpler and follows existing pattern
   - Will use Traefik labels (step 5) unless the user prefers file provider

#### Phase D — Makefile and .env

10. **Add `deploy-crowdsec` target to `makefile`:**
    ```makefile
    deploy-crowdsec: pull
        { \
        echo "Deploying the crowdsec stack..." ;\
        set -a ;\
        . ./swarm/.env ;\
        set +a ;\
        docker stack deploy --compose-file ./swarm/crowdsec.yml crowdsec ;\
        }
    ```
    Also add `remove-crowdsec` target.

11. **Document required `.env` variables:**
    - `CROWDSEC_LAPI_KEY=<generate with: openssl rand -base64 32>` — LAPI admin key
    - `CROWDSEC_BOUNCER_KEY=<register via: docker exec crowdsec_crowdsec.1.<id> cscli bouncers add traefik-bouncer>` — bouncer API key
    - Or automate bouncer registration via a setup script

#### Phase E — Post-deploy setup (manual or scripted)

12. **Register the bouncer** with CrowdSec LAPI after first deploy:
    - Either document manual step: `docker service ps crowdsec_crowdsec --no-trunc` to get container ID, then `docker exec -it <container> cscli bouncers add traefik-bouncer`
    - Or add a one-shot init approach using `crowdsecurity/bouncer-helper`
    - Or generate the bouncer key upfront and use `cscli bouncers add traefik-bouncer --key <key>` in a setup script

13. **Add Traefik container label** for CrowdSec acquisition (in `swarm/core.yml`):
    - Traefik itself needs `crowdsec.enable=true` label so CrowdSec picks up its logs
    - This is a Docker label (not a Traefik label) — add via `deploy.labels` on the Traefik service

14. **Verify protection** — hit a monitored service with a test attack pattern and confirm 403 from the bouncer

### Relevant files

| File | Action | Details |
|------|--------|---------|
| `swarm/crowdsec.yml` | **Rewrite** | Full Swarm stack: crowdsec LAPI + traefik-bouncer + socket-proxy |
| `swarm/core.yml` | **Modify** | Add crowdsec-bouncer middleware label, entrypoint middleware, Traefik crowdsec label |
| `swarm/crowdsec/acquis.yaml` | **Minor update** | Add comments about Traefik label requirements |
| `makefile` | **Modify** | Add `deploy-crowdsec` and `remove-crowdsec` targets |
| `swarm/.env` | **Modify** | Add `CROWDSEC_LAPI_KEY` and `CROWDSEC_BOUNCER_KEY` vars |

### Verification

1. **Stack validation:** `docker stack deploy --compose-file ./swarm/crowdsec.yml crowdsec --dry-run` (or manually `docker compose -f swarm/crowdsec.yml config` to validate syntax)
2. **Service health:** `docker service ls | grep crowdsec` → all services running
3. **LAPI health:** `curl http://localhost:8080/health` from manager node (if LAPI port exposed temporarily)
4. **Bouncer connectivity:** Check `docker service logs crowdsec_traefik-bouncer` for successful LAPI connection
5. **Traefik middleware:** `docker service logs core_traefik` should show no errors about missing middleware
6. **End-to-end:** Visit a protected HTTPS service → confirm it loads. Check CrowdSec metrics: `docker exec -it <crowdsec-container> cscli metrics`
7. **Block test:** Simulate an attack or manually add a decision: `docker exec -it <crowdsec-container> cscli decisions add --ip <test-ip>` → confirm that IP gets 403

### Decisions

- **Bouncer approach:** ForwardAuth (separate traefik-bouncer container) over Traefik plugin — avoids custom Traefik builds, works cleanly with Swarm
- **Protection scope:** All HTTPS services via `--entrypoints.https.http.middlewares=crowdsec-bouncer@swarm` — applies globally
- **Log acquisition:** Docker logs via socket-proxy (existing pattern), collection changed from `crowdsecurity/nginx` → `crowdsecurity/traefik`
- **Socket-proxy:** Updated with `SWARM: 1` for Swarm Docker API compatibility
- **LAPI exposure:** Internal only (no host port) — bouncer reaches LAPI via overlay network

### Out of scope

- CrowdSec AppSec / WAF component (can be added later)
- Non-HTTP entrypoints (smtp, mqtt, etc.) — not protected by the bouncer
- CrowdSec dashboard / Prometheus metrics integration (can be added later)
- Retroactively adding the crowdsec middleware to existing service routers (entrypoint-level handles this globally)
- Bouncer key registration automation script (documented manual step for now; can be automated later)

### Further Considerations

1. **Bouncer key registration:** Will use manual `cscli bouncers add` post-deploy. Could automate later with an init container or a swarm cronjob.
2. **Host config directory:** `/var/data/crowdsec/` needs to exist on the Swarm node before deploy. Will add a `setup-crowdsec` make target or document as prerequisite.
3. **Local/development env:** There's also `local.yml` and `swarm/local_core.yml` — should crowdsec be added to those too? Skipping for now unless the user asks.
