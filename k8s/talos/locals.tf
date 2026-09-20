locals {
  cluster_name      = "fouadflix-talos"
  cluster_endpoint  = "https://talos.homelab.fouad.dev:6443"
  cluster_vip       = "192.168.200.70"

  # renovate: datasource=github-releases depName=siderolabs/talos
  talos_version = "v1.13.0"
  # renovate: datasource=github-releases depName=kubernetes/kubernetes
  kubernetes_version = "v1.35.0"

  nodes = {
    controlplane = {
      talos-cp-00 = {
        ip = "192.168.200.60"
      },
      talos-cp-01 = {
        ip = "192.168.200.61"
      },
      talos-cp-02 = {
        ip = "192.168.200.62"
      }
    }

    controlplane_bare_metal = {
      # control-plane-00 = {
      #   ip = "192.168.200.60"
      # },
      # control-plane-01 = {
      #   ip = "192.168.200.61"
      # },
      # control-plane-02 = {
      #   ip = "192.168.200.62"
      # }
    }
  }

  machine_secrets = jsondecode(
    jsondecode(
      base64decode(ephemeral.scaleway_secret_version.talos_secrets_v1.data)
    )["machine_secrets"]
  )

  common_patches = [
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
    })
  ]
}
