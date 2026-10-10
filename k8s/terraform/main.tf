terraform {
  cloud {
    organization = "fouadflix"

    workspaces {
      name = "k8s"
    }
  }

  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.114.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "1.4.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.3.0"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.17.0"
    }
  }
}

provider "hcp" {}

provider "sops" {}

provider "kubernetes" {
  config_path = "~/.kube/configs/fouadflix-talos"
}

provider "argocd" {
  server_addr = "argocd.homelab.fouad.dev"
  username    = "admin"
  password    = ephemeral.sops_file.secrets.data["argocd.admin-password"]
}

ephemeral "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}
