# Self-hosted Mail Server (Docker Swarm)

This stack uses Docker Mailserver and can reuse the certificate issued by Traefik.

## 1) Configure mail domain

Edit [swarm/mailserver/docker-mailserver.env](swarm/mailserver/docker-mailserver.env):

- OVERRIDE_HOSTNAME: mail host FQDN (example: mail.example.com)
- OVERRIDE_DOMAINNAME: root mail domain (example: example.com)
- POSTMASTER_ADDRESS: postmaster mailbox

## 2) Sync Traefik cert for mailserver

Traefik stores certificates in `/mnt/data/config/traefik/acme.json`.
Mailserver needs cert files (`fullchain.pem` and `privkey.pem`).

Run:

`./scripts/mailserver-sync-traefik-cert.sh /mnt/data/config/traefik/acme.json mail.example.com`

This writes:

- `/mnt/data/docker-mailserver/ssl/fullchain.pem`
- `/mnt/data/docker-mailserver/ssl/privkey.pem`

## 3) DNS records (required)

Create these DNS records for your mail domain:

- A: mail.example.com -> your public IP
- MX: example.com -> mail.example.com (priority 10)
- SPF TXT: v=spf1 mx a:mail.example.com -all # v=spf1 include:spf.efwd.registrar-servers.com ~all
- DKIM TXT: mail._domainkey.example.com -> generated DKIM key
- DMARC TXT: _dmarc.example.com -> v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com

## 4) Open ports

Ensure inbound TCP is open to your Traefik manager node for:

- 25 (SMTP)
- 587 (Submission)
- 993 (IMAPS)
- 995 (POP3S)

Mail ports are exposed by [swarm/core.yml](swarm/core.yml) and routed to [swarm/mailserver.yml](swarm/mailserver.yml) via TCP labels.

## 5) Deploy

`make deploy-mailserver`

## 6) Create mailbox accounts

`docker exec -it $(docker ps --filter name=mailserver_mail --format '{{.ID}}' | head -n 1) setup email add user@example.com 'StrongPasswordHere'`

`docker exec -it $(docker ps --filter name=mailserver_mail --format '{{.ID}}' | head -n 1) setup alias add postmaster@example.com user@example.com`

## 7) Verify

- Check service status: `docker service ls | grep mailserver`
- Check logs: `docker service logs -f mailserver_mail`

## Repository-wide `/var/data` migration plan

Target: replace the active bind-mount base path `/var/data` with `/mnt/data`.
Docker named volumes, including the mailserver's `mail_data`, `mail_state`,
`mail_logs`, and `mail_config`, are not part of this migration.

### 1) Prepare and inventory

1. Confirm `/mnt/data` is on persistent storage on every Swarm node that may run
   a service with a host bind mount.
2. Verify free space on each node with `df -h /var/data /mnt/data`.
3. Record the current service state:
   - `docker service ls`
   - `docker stack ls`
4. Back up `/var/data`, then copy it initially without stopping services:

   ```bash
   sudo mkdir -p /mnt/data
   sudo rsync -aHAXS --numeric-ids /var/data/ /mnt/data/
   ```

   Run this on every node that hosts data, not only on a manager. Host bind
   mounts are node-local.

5. Treat any rsync nonzero exit status as a failed copy. Do not deploy the new
   paths after a partial copy. Diagnose metadata access first:

   ```bash
   sudo stat /var/data/config/traefik/acme.json
   sudo ls -ldn /var/data/gitea_data/gitea/data/indexers \
     /var/data/gitea_data/gitea/data/indexers/issues.bleve
   sudo namei -l /var/data/gitea_data/gitea/data/indexers/issues.bleve
   findmnt -T /var/data -o TARGET,SOURCE,FSTYPE,OPTIONS
   ```

   `get_xattr_names: ... Permission denied` means rsync can access the file
   data but cannot preserve its extended attributes. On filesystems where
   xattrs are unsupported or protected by policy, verify that the files do not
   rely on security-relevant xattrs, then rerun without `-X`:

   ```bash
   sudo rsync -aHAS --numeric-ids /var/data/ /mnt/data/
   ```

   Do not use this fallback merely because `acme.json` is unreadable; the copy
   must still be able to read file contents. `readlink_stat: ... Permission
   denied` is different: it means metadata or a parent directory is
   inaccessible. Check the path's ownership/mode, ACLs, MAC policy, and whether
   `/var/data` is a network filesystem with root squash. Stop the owning
   service during the final sync, but do not `chmod 777` or recursively change
   ownership. If root is squashed by a remote filesystem, run the copy from the
   filesystem server or as an account with the required directory permissions.
   Repeat the copy until it exits successfully.

6. Keep the source tree until the migration has been verified. Do not remove
   `/var/data` as part of the cutover.

### 2) Update repository references

In one change, replace active `/var/data` references with `/mnt/data` in:

- Swarm stack files under `swarm/`
- Host setup recipes in `makefile`
- `scripts/mailserver-sync-traefik-cert.sh`
- Operational comments and documentation

Do not change `archive/`. Recheck the result with:

```bash
rg -n --glob '!archive/**' '/var/data' .
```

Update any external automation and node bootstrap scripts that write to the
same host directory. Environment files, Traefik `acme.json`, mailserver
certificates, database data, and read-only configuration files must all point
to the equivalent path below `/mnt/data`.

Before deployment, render every changed Compose/Swarm file that can be rendered
locally and review the resulting bind-mount source paths. For the main Compose
configuration, use:

```bash
docker compose -f compose.yml config
```

### 3) Cut over

1. Announce a maintenance window and stop external writes where possible.
2. Scale to zero or otherwise stop every service that writes to `/var/data`.
   Read-only services may stay running until their stack is redeployed, but
   stopping all affected services avoids mixed-path writes.
3. Stop any process that can change a copied file during the final copy. In
   particular, quiesce any external process that writes the Traefik
   `acme.json` path used by the certificate sync script.
4. Perform the final metadata-preserving copy on every applicable node:

   ```bash
   sudo rsync -aHAXS --numeric-ids /var/data/ /mnt/data/
   ```

   Use the documented no-xattr form instead only where xattr preservation was
   already investigated and intentionally ruled out. Both the initial and
   final copies must complete with exit status zero.

   Review the old and new trees with:

   ```bash
   sudo rsync -aHAXnc --numeric-ids /var/data/ /mnt/data/
   ```

   No output should be expected.
5. Deploy the updated stacks from a manager. The stack `env_file` paths,
   including the mailserver environment file, are resolved during deployment.
6. Resync the mailserver certificate from its new source/destination paths:

   ```bash
   ./scripts/mailserver-sync-traefik-cert.sh \
     /mnt/data/config/traefik/acme.json mail.example.com
   ```

7. Confirm services converge with `docker service ps <service> --no-trunc`
   and inspect each changed service with `docker service inspect`.

### 4) Verify

- Confirm no running container still uses `/var/data`:

  ```bash
  docker ps -q | xargs -r docker inspect \
    --format '{{.Name}} {{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
  ```

  Run this command on every Swarm node.

- Check that databases, mail delivery, Traefik certificates, monitoring,
  CrowdSec, and web applications can read and write normally.
- Confirm new files appear under `/mnt/data` rather than `/var/data`.
- Keep the old directory read-only and retained for at least one verified
  backup/restore cycle.

### 5) Roll back

If verification fails:

1. Stop the affected services before copying anything back.
2. Revert the repository path change and redeploy the affected stacks.
3. If writes occurred below `/mnt/data`, copy only the required changed data
   back after confirming application consistency; do not blindly replace an
   older `/var/data` tree.
4. Bring services back in dependency order and verify them again.

Remove `/var/data` only after the new path has remained healthy through the
chosen retention period and a separate backup has been confirmed.

