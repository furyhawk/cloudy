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
- Python 3.11
- Build for ARM64 platform

## Local Deployment
#### Python:
1. `cd src`
2. `pip install -r requirements.txt`
3. `streamlit run app.py`

#### Docker:
1. `docker compose -f local.yml up --build`

## Production Deployment
1. In `compose/traefik/traefik.yml`, change `example@test.com` to your email.
2. In `compose/traefik/traefik.yml`, change `example.com` to your domain.
3. `sudo apt-get install build-essential`
4. `mdkir ~/st-sync`
5. `mdkir ~/.thelounge`
6. `touch cache/bar_cache.sqlite`
7. `touch cache/short_cache.sqlite`
8. `make serve`

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
