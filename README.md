# Infrastructure as Code

[![Cloudflare](https://github.com/fouadchamoun/infrastructure/actions/workflows/cloudflare.yml/badge.svg)](https://github.com/fouadchamoun/infrastructure/actions/workflows/cloudflare.yml)

This repository contains the configuration for my personal infrastructure. It is managed using a combination of Terraform and ArgoCD to automate the setup and maintenance of various services.

## Repository Structure

```bash
├── cloudflare
│   ├── ad_block # Terraform config for ad-blocking solution using Cloudflare Zero Trust Gateway Policies
│   └── main # Terraform config for managing Cloudflare resources (DNS records, Zero Trust policies, and other settings)
├── k8s # Kubernetes cluster
│   ├── apps
│   │   ├── cloudflared
│   │   ├── ...
│   │   └── public-apps
│   │       └── ...
│   ├── bootstrap
│   │   ├── 0-argocd.yaml
│   │   ├── 0-coredns-config.yaml
│   │   ├── 0-local-path-provisioner.yaml
│   │   ├── 0-longhorn.yaml
│   │   ├── 1-cert-manager.yaml
│   │   ├── 1-external-secrets.yaml
│   │   ├── 2-cnpg.yaml
│   │   ├── 2-kubevirt.yaml
│   │   ├── 2-monitoring.yaml
│   │   ├── 2-traefik.yaml
│   │   ├── 3-appset-git-directories.yaml
│   │   ├── 3-appset-pull-requests.yaml
│   ├── charts
│   │   └── base-app
│   ├── talos # Talos Linux cluster provisioning and config (3 baremetal nodes)
│   └── terraform # Terraform config for managing K8S ressources
└── secrets # Encrypted secrets pushed to Scaleway Secrets Manager
```

## Technologies Used

- **Talos**: immutable Kubernetes distribution.
  - **Argo CD**: GitOps continuous delivery tool.
  - **External Secrets Operator**: secrets management.
  - **Grafana Cloud + Alloy**: monitoring and observability.
  - **Cloudflare**: DNS management and Zero Trust security.
  - **Traefik**: reverse proxy and load balancer.
- **Longhorn**: software-defined storage for Kubernetes.
- **SOPS**: secrets management.
- **Terraform**: infrastructure as code to manage the cluster and Cloudflare resources.

## Contributing

This is a personal project, but feel free to open an issue if you find any problems or have any suggestions.
