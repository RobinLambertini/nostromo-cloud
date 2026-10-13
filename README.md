# nostromo-cloud

Infrastructure as Code pour un serveur bare metal Scaleway (Debian 13, Docker, Traefik, Pocket ID, Forgejo).

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- Un serveur bare metal Scaleway existant (EM-A116X-SSD, fr-par-2)
- Un domaine avec accès aux DNS

## Structure

```
terraform/   — provisioning du serveur (import uniquement, pas de création)
ansible/     — configuration du serveur (Docker, Traefik, Pocket ID, Forgejo, Dockhand…)
Makefile     — commandes principales
```

## Mise en place

### 1. Terraform

Copier et renseigner les secrets :

```bash
cp terraform/secret.tfvars.example terraform/secret.tfvars
```

Renseigner dans `terraform/secret.tfvars` :
- `scw_access_key` / `scw_secret_key` — clés API Scaleway
- `ssh_key_id` — ID de la clé SSH dans l'interface Scaleway
- `baremetal_server_id` — ID du serveur (visible dans l'URL de la console Scaleway)

> Le serveur doit être créé manuellement via la console Scaleway. Terraform gère l'état uniquement via import.

Importer le serveur dans l'état Terraform :

```bash
make init
make provision   # applique l'import block dans main.tf
```

Après un `make provision` réussi : supprimer le bloc `import {}` de `terraform/main.tf`.

### 2. Ansible

**Inventory :**

```bash
cp ansible/inventory.ini.example ansible/inventory.ini
```

Remplacer `<YOUR_SERVER_IP>` par l'IP du serveur (`make provision` affiche `server_ip`).

**Variables secrètes (vault) :**

```bash
cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml
```

Renseigner `traefik_dashboard_users` avec un hash htpasswd :

```bash
htpasswd -nb admin <MON_MOT_DE_PASSE>
```

Renseigner aussi le compte admin Forgejo (`forgejo_admin_username`, `forgejo_admin_email`, `forgejo_admin_password`). Le nom `admin` est réservé par Forgejo.

Chiffrer le fichier :

```bash
ansible-vault encrypt ansible/group_vars/all/vault.yml
```

**Déploiement :**

```bash
make configure
# ou avec vault chiffré :
cd ansible && ansible-playbook main.yml --ask-vault-pass
```

### 3. DNS

Pointer les enregistrements A suivants vers l'IP du serveur :

| Domaine | Service |
|---|---|
| `traefik.<domain>` | Dashboard Traefik |
| `auth.<domain>` | Pocket ID (SSO OIDC, passkeys) |
| `stacks.<domain>` | Dockhand |
| `git.<domain>` | Forgejo |
| `coder.<domain>` et `*.coder.<domain>` | Coder (interface + apps des workspaces) |

### Certificats wildcard (Coder)

Let's Encrypt n'émet un certificat wildcard qu'en challenge DNS-01. Le compose Traefik embarque donc [acme-dns](https://github.com/joohoi/acme-dns), un mini serveur DNS (port 53) qui ne sert que les TXT des challenges, et un second resolver `letsencrypt-dns` qui l'utilise. Aucune clé API du registrar n'est nécessaire.

1. Dans la zone DNS, déléguer `acme.<domain>` au serveur :

   | Type | Sous-domaine | Cible |
   |---|---|---|
   | A | `ns-acme` | IP du serveur |
   | NS | `acme` | `ns-acme.<domain>.` |

2. `make configure`, puis dans le compose de Coder utiliser le resolver `letsencrypt-dns` :

   ```yaml
   - "traefik.http.routers.coder-apps.tls.certresolver=letsencrypt-dns"
   - "traefik.http.routers.coder-apps.tls.domains[0].main=coder.<domain>"
   - "traefik.http.routers.coder-apps.tls.domains[0].sans=*.coder.<domain>"
   ```

3. Au premier essai, Traefik s'inscrit auprès d'acme-dns et logue le CNAME à créer (`docker logs traefik 2>&1 | grep CNAME`). L'ajouter dans la zone :

   | Type | Sous-domaine | Cible |
   |---|---|---|
   | CNAME | `_acme-challenge.coder` | `<uuid>.acme.<domain>.` |

4. `docker restart traefik` : le certificat est émis, les renouvellements sont ensuite automatiques. Le compte acme-dns est dans `/home/nostromo/data/traefik/acme-dns/accounts.json` (à sauvegarder avec `acme.json`).

### 4. Pocket ID

Au premier déploiement, créer le compte admin (avec une passkey) sur `https://auth.<domain>/setup`.
La clé de chiffrement est générée automatiquement dans `/home/nostromo/apps/pocket-id/.env` : à sauvegarder avec `/home/nostromo/data/pocket-id`.

### 5. Forgejo

Le compte admin défini dans le vault est créé automatiquement au premier déploiement.
Git passe uniquement par HTTPS (pas de SSH) : créer un token d'accès dans *Paramètres → Applications* et l'utiliser comme mot de passe lors d'un `git clone` / `git push`.
Les inscriptions sont fermées, sauf via Pocket ID.

**SSO Pocket ID :**

1. Dans Pocket ID, créer un client OIDC `Forgejo` avec la callback `https://git.<domain>/user/oauth2/pocket-id/callback`.
2. Dans l'onglet *Access* du client, autoriser les groupes qui ont accès à Forgejo (ex. `DevSecOps`, plus tard `developer`).
3. Renseigner `forgejo_oidc_client_id` et `forgejo_oidc_client_secret` dans le vault, puis `make configure`.

Les membres du groupe `forgejo_oidc_admin_group` (`group_vars/all/vars.yml`) sont admins de Forgejo, les autres groupes autorisés sont utilisateurs normaux. Le statut admin est recalculé à chaque connexion.
Tout est stocké dans `/home/nostromo/data/forgejo` (dépôts, base SQLite, `custom/conf/app.ini`) : c'est le dossier à sauvegarder.

## Commandes disponibles

```bash
make init        # initialise Terraform
make plan        # prévisualise les changements Terraform
make provision   # applique Terraform
make configure   # lance le playbook Ansible
make deploy      # plan + provision + configure
make ping        # vérifie la connectivité Ansible
```

## Fichiers secrets (jamais commités)

| Fichier | Contenu |
|---|---|
| `terraform/secret.tfvars` | Clés API Scaleway, IDs |
| `terraform/terraform.tfvars` | IDs OS, zone |
| `ansible/inventory.ini` | IP du serveur |
| `ansible/group_vars/all/vault.yml` | Hash htpasswd Traefik, compte admin Forgejo |