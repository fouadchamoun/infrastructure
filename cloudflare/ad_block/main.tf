terraform {
  cloud {
    organization = "fouadflix"

    workspaces {
      name = "ad_block"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.25.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.6.2"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

