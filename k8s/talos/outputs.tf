output "installer_image_url_baremetal" {
  value = data.talos_image_factory_urls.baremetal.urls.installer
}
output "installer_iso_url_baremetal" {
  value = data.talos_image_factory_urls.baremetal.urls.iso
}

output "machine_config_hashes_baremetal" {
  value = { for node_name, config in talos_machine_configuration_apply.controlplane : node_name => config.machine_configuration_hash }
}

output "not_before" {
  value = terraform_data.not_before
}
