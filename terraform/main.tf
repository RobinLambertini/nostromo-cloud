data "scaleway_baremetal_offer" "em_a116x" {
  zone                = var.scaleway_zone
  name                = "EM-A116X-SSD"
  subscription_period = "monthly"
}

resource "scaleway_baremetal_server" "nostromo-cloud" {
  name                     = "nostromo-cloud"
  offer                    = data.scaleway_baremetal_offer.em_a116x.offer_id
  os                       = var.debian_13_os_id
  ssh_key_ids              = [var.ssh_key_id]
  install_config_afterward = false
  protected                = false
}

import {
  id = "fr-par-2/${var.baremetal_server_id}"
  to = scaleway_baremetal_server.nostromo-cloud
}
