terraform {
  cloud {
    organization = "fouadflix"

    workspaces {
      name = "cloudflare"
    }
  }

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.24.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.6.2"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "../secrets.yaml"
}

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["cloudflare.token"]
}

locals {
  domain     = "fouad.dev"
  account_id = data.sops_file.secrets.data["cloudflare.account_id"]
  zone_id    = data.sops_file.secrets.data["cloudflare.zone_id"]
}
