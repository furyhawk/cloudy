# Self-hosted Mail Server (Docker Swarm)

This stack uses Docker Mailserver and is deployed with:

make deploy-mailserver

## 1) Configure mail domain

Edit swarm/mailserver/docker-mailserver.env:

- OVERRIDE_HOSTNAME: mail host FQDN (example: mail.example.com)
- OVERRIDE_DOMAINNAME: root mail domain (example: example.com)
- POSTMASTER_ADDRESS: postmaster mailbox
- SSL_DOMAIN: certificate domain for mail TLS

## 2) DNS records (required)

Create these DNS records for your mail domain:

- A: mail.example.com -> your public IP
- MX: example.com -> mail.example.com (priority 10)
- SPF TXT: v=spf1 mx a:mail.example.com -all
- DKIM TXT: mail._domainkey.example.com -> generated DKIM key
- DMARC TXT: _dmarc.example.com -> v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com

## 3) Open ports

Ensure inbound TCP is open to your Traefik manager node for:

- 25 (SMTP)
- 587 (Submission)
- 993 (IMAPS)
- 995 (POP3S)

Mail ports are exposed by the Traefik service in [swarm/core.yml](swarm/core.yml), then routed to the mail service using TCP labels in [swarm/mailserver.yml](swarm/mailserver.yml).

## 4) Deploy

make deploy-mailserver

## 5) Create mailbox accounts

Use the Docker Mailserver setup helper from a manager node:

docker exec -it $(docker ps --filter name=mailserver_mail --format '{{.ID}}' | head -n 1) setup email add user@example.com 'StrongPasswordHere'

docker exec -it $(docker ps --filter name=mailserver_mail --format '{{.ID}}' | head -n 1) setup alias add postmaster@example.com user@example.com

## 6) Verify

- Check service status: docker service ls | grep mailserver
- Check logs: docker service logs -f mailserver_mail
- Send a test from an external mailbox and confirm delivery.

## Notes

- Mail data is persisted in named volumes: mail_data, mail_state, mail_logs, mail_config.
- For high deliverability, add PTR/rDNS with your server provider and keep SPF/DKIM/DMARC aligned.
