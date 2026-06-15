# nostromo-cloud

Infrastructure as Code pour un serveur bare metal Scaleway (Debian 13, Docker, Traefik, Authentik).

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- [scw CLI](https://www.scaleway.com/en/cli/) (pour `make reinstall` uniquement)
- Un serveur bare metal Scaleway existant (EM-A116X-SSD, fr-par-2)
- Un domaine avec accès aux DNS

## Structure

```
terraform/   — provisioning du serveur (import uniquement, pas de création)
ansible/     — configuration du serveur (Docker, Traefik, Authentik, Dockhand…)
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
cp ansible/group_vars/vault.yml.example ansible/group_vars/vault.yml
```

Renseigner `traefik_dashboard_users` avec un hash htpasswd :

```bash
htpasswd -nb admin <MON_MOT_DE_PASSE>
```

Chiffrer le fichier :

```bash
ansible-vault encrypt ansible/group_vars/vault.yml
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
| `auth.<domain>` | Authentik SSO |
| `stacks.<domain>` | Dockhand |

## Commandes disponibles

```bash
make init        # initialise Terraform
make plan        # prévisualise les changements Terraform
make provision   # applique Terraform
make configure   # lance le playbook Ansible
make deploy      # plan + provision + configure
make ping        # vérifie la connectivité Ansible
make reinstall   # réinstalle l'OS (confirmation requise, données effacées)
```

## Réinstallation OS

Pour remettre le serveur à zéro sans changer d'IP ni de facturation :

```bash
make reinstall   # demande confirmation "REINSTALL"
# ~15-20 min, puis :
make configure
```

## Fichiers secrets (jamais commités)

| Fichier | Contenu |
|---|---|
| `terraform/secret.tfvars` | Clés API Scaleway, IDs |
| `terraform/terraform.tfvars` | IDs OS, zone |
| `ansible/inventory.ini` | IP du serveur |
| `ansible/group_vars/vault.yml` | Hash htpasswd Traefik |