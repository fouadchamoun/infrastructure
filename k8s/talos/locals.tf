locals {
  cluster_name      = "fouadflix-talos"
  cluster_endpoint  = "https://talos.homelab.fouad.dev:6443"
  cluster_vip       = "192.168.200.70"

  # renovate: datasource=github-releases depName=siderolabs/talos
  talos_version = "v1.14.2"
  # renovate: datasource=github-releases depName=kubernetes/kubernetes
  kubernetes_version = "v1.35.0"

  nodes = {
    controlplane = {
      control-plane-00 = {
        ip = "192.168.200.60"
        control_ip = "192.168.200.60"
      },
      control-plane-01 = {
        ip = "192.168.200.61"
        control_ip = "192.168.200.61"
      },
      control-plane-02 = {
        ip = "192.168.200.62"
        control_ip = "192.168.200.62"
      }
    }
  }

  machine_secrets = jsondecode(
    jsondecode(
      base64decode(ephemeral.scaleway_secret_version.talos_secrets_v1.data)
    )["machine_secrets"]
  )
}
