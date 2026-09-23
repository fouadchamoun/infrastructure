terraform {
  cloud {
    organization = "fouadflix"

    workspaces {
      name = "talos"
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
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    scaleway = {
      source = "scaleway/scaleway"
      version = "2.83.1"
    }
  }
}

provider "hcp" {}

provider "sops" {}

provider "scaleway" {
  profile = "personal-secrets-manager"
}
