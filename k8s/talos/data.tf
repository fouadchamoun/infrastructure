data "talos_image_factory_urls" "nocloud" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.nocloud.id

  platform      = "nocloud"
  architecture  = "amd64"
}

data "talos_image_factory_urls" "baremetal" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.baremetal.id

  platform      = "metal"
  architecture  = "amd64"
}
