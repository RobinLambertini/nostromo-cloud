variable "scaleway_zone" { 
    type = string
    description = "Zone scaleway"
    default = "fr-par-2"
}

variable "scaleway_region" { 
    type = string
    description = "Region Scaleway"
    default = "fr-par"
}

variable "baremetal_server_id" { 
    type = string
    description = "ID du Bare Metal"
    sensitive = true
}

variable "ssh_key_id" { 
    type = string
    description = "Clé SSH"
}

variable "debian_12_os_id" {
  type        = string
  description = "L'UUID de l'OS Debian 12 (Bookworm)"
}

variable "debian_13_os_id" {
  type        = string
  description = "L'UUID de l'OS Debian 13 (Trixie)"
}

variable "proxmox_debian_13_id" {
  type        = string
  description = "L'UUID de l'OS Proxmox à base de Debian 13 (Trixie)"
}

variable "scw_access_key" {
  type      = string
  sensitive = true
}

variable "scw_secret_key" {
  type      = string
  sensitive = true
}