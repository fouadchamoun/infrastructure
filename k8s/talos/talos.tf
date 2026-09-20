# Step 1: Generate and store machine secrets in Scaleway Secret Manager
# The ephemeral resource generates secrets only when needed (first run)
ephemeral "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

resource "scaleway_secret" "talos_secrets" {
  name = "machine_secrets"
  path = "/talos"
  type = "key_value"

  tags = ["terraform"]
}

resource "scaleway_secret_version" "talos_secrets_v1" {
  secret_id = scaleway_secret.talos_secrets.id

  data_wo = jsonencode({
    machine_secrets = jsonencode(ephemeral.talos_machine_secrets.this.machine_secrets)
  })

  # Hardcoded version prevents unnecessary refreshes after initial creation
  data_wo_version = 1
}

# Step 2: Retrieve machine secrets ephemerally from Scaleway Secret Manager
# This runs on every terraform operation but values are never stored in state
ephemeral "scaleway_secret_version" "talos_secrets_v1" {
  secret_id  = scaleway_secret.talos_secrets.id
  revision   = "latest"
  depends_on = [scaleway_secret_version.talos_secrets_v1]
}

# Step 3: Generate ephemeral client configuration using retrieved machine secrets
# Persist the admin cert NotBefore timestamp in regular Terraform state.
# Use ignore_changes so it is set once and never updated automatically.
# To rotate the cert: taint this resource and re-apply.
resource "terraform_data" "not_before" {
  input = plantimestamp()
  lifecycle {
    ignore_changes = [input]
  }
}

ephemeral "talos_client_configuration" "this" {
  cluster_name    = local.cluster_name
  machine_secrets = local.machine_secrets

  not_before      = terraform_data.not_before.output

  endpoints       = [for node in local.nodes.controlplane : node.ip]
  nodes           = [for node in local.nodes.controlplane : node.ip]
}

resource "terraform_data" "talosconfig" {
  triggers_replace = terraform_data.not_before.output

  provisioner "local-exec" {
    command = "echo \"${ephemeral.talos_client_configuration.this.talos_config}\" > $HOME/.talos/config"
  }
}

# Step 4: Generate machine configuration
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        extraKernelArgs = []
        systemExtensions = {
          officialExtensions = [
            "siderolabs/drbd",
            "siderolabs/intel-ucode",
            "siderolabs/qemu-guest-agent",
            "siderolabs/thunderbolt",
            "siderolabs/iscsi-tools",
            "siderolabs/util-linux-tools"
          ]
        }
      }
    }
  )
}

ephemeral "talos_machine_configuration" "controlplane" {
  for_each = local.nodes.controlplane

  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = local.machine_secrets

  machine_type     = "controlplane"
  talos_version    = local.talos_version
  kubernetes_version = local.kubernetes_version

  config_patches = [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
        apiServer = {
          extraArgs = {
            default-not-ready-toleration-seconds = "30"
            default-unreachable-toleration-seconds = "30"
          }
          certSANs = [
            "k8s.homelab.fouad.dev"
          ]
        }
        scheduler = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
        controllerManager = {
          extraArgs = {
            bind-address = "0.0.0.0"
            node-monitor-period = "2s"
            node-monitor-grace-period = "20s"
          }
        }
        proxy = {
          extraArgs = {
            metrics-bind-address = "0.0.0.0:10249"
          }
        }
      }
    }),
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.this.urls.installer
          diskSelector = {
            size = "<= 500GB"
          }
        }
        sysctls = {
          "user.max_user_namespaces" = "63556"
        }
        kernel = {
          modules = [
            {
              name       = "drbd"
              parameters = [
                "usermode_helper=disabled"
              ]
            },
            {
              name = "drbd_transport_tcp"
            }
          ]
        }
        kubelet = {
          extraConfig = {
            imageMaximumGCAge = "24h"
          }
          extraArgs = {
            node-status-update-frequency = "4s"
          }

          extraMounts = [
            {
              source = "/var/mnt/longhorn"
              destination = "/var/mnt/longhorn" # set as longhorn default data path
              type = "bind"
              options = [
                "bind",
                "rshared",
                "rw"
              ]
            }
          ]
        }
        features = {
          hostDNS = {
            enabled = true
            forwardKubeDNSToHost = true
            resolveMemberNames = true
          }
        }
      }
    }),
    templatefile("${path.module}/assets/network-config.yaml.tftpl", {
      hostname = each.key
      ip_cidr = "${each.value.ip}/24"
      ip_gateway = "192.168.200.1"
      ip_vip = local.cluster_vip
    }),
    templatefile("${path.module}/assets/user-volume-config.yaml.tftpl", {})
  ]
}

# Step 5: Apply configuration using write-only input
resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.nodes.controlplane

  client_configuration_wo        = ephemeral.talos_client_configuration.this.client_configuration
  machine_configuration_input_wo = ephemeral.talos_machine_configuration.controlplane[each.key].machine_configuration
  node                           = each.key
  endpoint                       = each.value.ip
  apply_mode                     = "staged_if_needing_reboot"
}
