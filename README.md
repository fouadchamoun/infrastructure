# Infrastructure as Code

[![Cloudflare](https://github.com/fouadchamoun/infrastructure/actions/workflows/cloudflare.yml/badge.svg)](https://github.com/fouadchamoun/infrastructure/actions/workflows/cloudflare.yml)

This repository contains the configuration for my personal infrastructure. It is managed using a combination of Ansible, Terraform and ArgoCD to automate the setup and maintenance of various services.

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
│   │   ├── 0-kube-vip.yaml
│   │   ├── 0-linstor.yaml
│   │   ├── 1-cert-manager.yaml
│   │   ├── 1-external-secrets.yaml
│   │   ├── 2-monitoring.yaml
│   │   ├── 2-traefik.yaml
│   │   ├── 3-appset-git-directories.yaml
│   │   ├── 3-appset-pull-requests.yaml
│   ├── charts
│   │   └── base-app
│   ├── talos # Talos config (terraform) for deploying a k8s cluster on PVE VMs
│   └── terraform # Terraform config for managing K8S ressources
├── pve # Proxmox Virtual Environment (PVE) cluster.
│   ├── roles # Collection of ansible roles for configuring PVE nodes
│   │   ├── intel_sriov # Intel vGPU
│   │   ├── linstor # Linstor storage cluster
│   │   └── pve_conf # Common PVE config
│   └── terraform # Terraform config for managing PVE ressources
└── secrets # Encrypted secrets pushed to Scaleway Secrets Manager
```

## Technologies Used

- **Proxmox Virtual Environment (PVE)**: virtualization platform.
- **Linstor**: software-defined storage for PVE & Kubernetes.
- **SOPS**: secrets management.
- **Ansible**: configuration management and application deployment.
- **Terraform**: infrastructure as code to manage resources in Proxmox and Cloudflare.
- **Talos**: immutable Kubernetes distribution.
  - **Argo CD**: GitOps continuous delivery tool.
  - **External Secrets Operator**: secrets management.
  - **Grafana Cloud + Alloy**: monitoring and observability.
  - **Cloudflare**: DNS management and Zero Trust security.
  - **Traefik**: reverse proxy and load balancer.

## Contributing

This is a personal project, but feel free to open an issue if you find any problems or have any suggestions.
