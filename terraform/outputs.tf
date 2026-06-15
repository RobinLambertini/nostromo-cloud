output "server_id" {
  value = split("/", scaleway_baremetal_server.nostromo-cloud.id)[1]
}

output "server_ip" {
  value = scaleway_baremetal_server.nostromo-cloud.ipv4[0].address
}
