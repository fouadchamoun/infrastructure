terraform {
  cloud {
    organization = "fouadflix"

    workspaces {
      name = "pve"
    }
  }

  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.114.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.113.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.2"
    }
  }
}

provider "hcp" {}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

provider "proxmox" {
  endpoint = "https://pve-0.homelab.fouad.dev:8006"

  api_token = data.sops_file.secrets.data["pve.terraform_api_token"]
}

provider "proxmox" {
  alias = "root"

  endpoint = "https://pve-0.homelab.fouad.dev:8006"

  username = "root@pam"
  password = data.sops_file.secrets.data["pve.root_password"]
}
