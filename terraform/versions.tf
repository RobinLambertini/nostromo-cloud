terraform {
  required_version = ">= 1.5.0"
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  zone       = var.scaleway_zone
  region     = var.scaleway_region
  access_key = var.scw_access_key
  secret_key = var.scw_secret_key
}