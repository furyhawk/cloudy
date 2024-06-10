![GitHub commit activity](https://img.shields.io/github/commit-activity/m/furyhawk/cloudy)

# Webapp + Streamlit + Traefik + Docker
This simple project uses Traefik as a reverse proxy to a Streamlit application and handles SSL certs with Lets Encrypt.

- [Chat](https://chat.furyhawk.lol/): Chat with AI.
- [Stock Analysis Assistant](https://fin.furyhawk.lol/): AI assistant using GROQ and llama3.
- [Redlib](https://redlib.furyhawk.lol/): Reddit libre.
- [Blog](https://info.furyhawk.lol/)
- [Beyond All Information](https://bai.furyhawk.lol/): analyse your [Beyond All Reason](https://www.beyondallreason.info/) games.
- [CheatSheets](https://cheat.furyhawk.lol/): Collection of cheatsheets.
- [Forum](https://forum.furyhawk.lol/): Host your own forum.
- [Neural Network Playground](https://furyhawk.github.io/playground): Understand neural network visually.
- [Note](https://note.furyhawk.lol/): Notepad Online.
- [pastebin](https://bin.furyhawk.lol/): Pastebin.
- [Home server](https://github.com/furyhawk/cloudy): Build for ARM64 platform

## Requirements
- Docker Compose
- Build for ARM64 platform

## Production Deployment
1. `git clone https://github.com/furyhawk/cloudy.git`
2. `cd cloudy`
3. `git submodule update --init --recursive`
4. In `compose/traefik/traefik.yml`, change `example@test.com` to your email.
5. In `compose/traefik/traefik.yml`, change `example.com` to your domain.
6. `sudo apt-get install build-essential` (if not already installed) to use makefile.
7. `mkdir ~/st-sync` syncthing folder.
8. `mkdir ~/site` public site folder.
9. `mkdir ./compose/config` to store config.
10. `cp .env.example ./compose/.env && cp .env ~/config/.env`
11. `cp ./compose/config/conf.php ~/config/conf.php`
12. `cp usersfile.example ./compose/usersfile`
13. `make serve`

### Notes:
```yaml
# Declaring the user list
#
# Note: when used in docker-compose.yml all dollar signs in the hash need to be doubled for escaping.
# To create user:password pair, it's possible to use this command:
# echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g
#
# Also note that dollar signs should NOT be doubled when they not evaluated (e.g. Ansible docker_container module).
labels:
  - "traefik.http.middlewares.test-auth.basicauth.users=test:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/,test2:$$apr1$$d9hr9HBB$$4HxwgUir3HP4EsggP/QNo0"
```

### TODO:

middleware:
```
# Enable HTTP Strict Transport Security (HSTS) to force clients to always connect via HTTPS
Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

# Enable cross-site filter (XSS) and tell browser to block detected attacks
X-XSS-Protection "1; mode=block"

# Prevent some browsers from MIME-sniffing a response away from the declared Content-Type
X-Content-Type-Options "nosniff"

# Disable some features
Permissions-Policy "accelerometer=(),ambient-light-sensor=(),autoplay=(),camera=(),encrypted-media=(),focus-without-user-activation=(),geolocation=(),gyroscope=(),magnetometer=(),microphone=(),midi=(),payment=(),picture-in-picture=(),speaker=(),sync-xhr=(),usb=(),vr=()"

# Disable some features (legacy)
Feature-Policy "accelerometer 'none';ambient-light-sensor 'none'; autoplay 'none';camera 'none';encrypted-media 'none';focus-without-user-activation 'none'; geolocation 'none';gyroscope 'none';magnetometer 'none';microphone 'none';midi 'none';payment 'none';picture-in-picture 'none'; speaker 'none';sync-xhr 'none';usb 'none';vr 'none'"

# Referer
Referrer-Policy "no-referrer"

# X-Robots-Tag
X-Robots-Tag "noindex, noarchive, nofollow"
```
