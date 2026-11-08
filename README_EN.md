# bc-ssh — SSH Bootcamp, Zero to Advanced

A **14-week**, **12 h/week** (168 h) self-paced bootcamp on **SSH** with OpenSSH 9.6+. You start without ever having used SSH and finish operating secure infrastructure access: keys, agents and FIDO2, client configuration, file transfer, server hardening, tunnels, bastion hosts, SSH certificates, 2FA, auditing and automation.

All content is in **Spanish**. Everything runs in a **Docker lab** (`compose.yaml`) with real SSH servers: `client`, `server`, `bastion` and `interno` (reachable only through `bastion`).

```bash
git clone https://github.com/ergrato-dev/bc-ssh.git
cd bc-ssh
docker compose up -d --build
docker compose run --rm client
```

- Week index and status: [bootcamp/README.md](bootcamp/README.md)
- Lab setup: [docs/setup-entorno.md](docs/setup-entorno.md)
- Autograding: `./scripts/verificar-semana.sh NN` ([docs/autograding.md](docs/autograding.md))
- Running project, `ssh-infra-kit`: [docs/proyecto-hilo-conductor.md](docs/proyecto-hilo-conductor.md)

License: [CC BY-NC-SA 4.0](LICENSE).
