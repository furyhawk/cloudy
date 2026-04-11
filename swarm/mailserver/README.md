# Self-hosted Mail Server (Docker Swarm)

This stack uses Docker Mailserver and can reuse the certificate issued by Traefik.

## 1) Configure mail domain

Edit [swarm/mailserver/docker-mailserver.env](swarm/mailserver/docker-mailserver.env):

- OVERRIDE_HOSTNAME: mail host FQDN (example: mail.example.com)
- OVERRIDE_DOMAINNAME: root mail domain (example: example.com)
- POSTMASTER_ADDRESS: postmaster mailbox

## 2) Sync Traefik cert for mailserver

Traefik stores certificates in `/var/data/config/traefik/acme.json`.
Mailserver needs cert files (`fullchain.pem` and `privkey.pem`).

Run:

`./scripts/mailserver-sync-traefik-cert.sh /var/data/config/traefik/acme.json mail.example.com`

This writes:

- `/var/data/docker-mailserver/ssl/fullchain.pem`
- `/var/data/docker-mailserver/ssl/privkey.pem`

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

