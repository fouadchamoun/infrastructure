resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "name" = "argocd"
    }
  }
}

resource "kubernetes_secret_v1" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  type = "Opaque"

  data_wo_revision = 2
  data_wo = {
    "admin.password"        = bcrypt(ephemeral.sops_file.secrets.data["argocd.admin-password"])
    "admin.passwordMtime"   = timestamp()
    "server.secretkey"      = ephemeral.sops_file.secrets.data["argocd.server-secretkey"]
    "webhook.github.secret" = ephemeral.sops_file.secrets.data["github-webhooks.secret"]
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "argocd_project" "cluster_bootstrap" {
  depends_on = [kubernetes_secret_v1.scw_sm_secret]

  metadata {
    name      = "cluster-bootstrap"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  spec {
    description = "Cluster Bootstrap"

    source_repos = [
      "https://github.com/fouadchamoun/infrastructure.git",
      "https://github.com/argoproj/argo-cd",
      "https://argoproj.github.io/argo-helm",
      "https://charts.longhorn.io",
      "ghcr.io/rancher/local-path-provisioner/charts",
      "quay.io/jetstack/charts",
      "https://charts.external-secrets.io",
      "https://traefik.github.io/charts",
      "ghcr.io/kite-org/charts",
      "ghcr.io/prometheus-community/charts",
      "ghcr.io/deliveryhero/helm-charts",
      "https://kubernetes-sigs.github.io/descheduler",
      "https://cloudnative-pg.github.io/charts"
    ]

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "argocd"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "kube-system"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "longhorn-system"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "local-path-storage"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "external-secrets"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "cert-manager"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "traefik"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "monitoring"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "kite-system"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "cnpg-system"
    }
  }
}

# Application - Cluster Bootstrap
resource "argocd_application" "cluster_bootstrap" {
  metadata {
    name      = "cluster-bootstrap"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  spec {
    project = argocd_project.cluster_bootstrap.metadata[0].name

    source {
      repo_url        = "https://github.com/fouadchamoun/infrastructure.git"
      target_revision = "main"
      path            = "k8s/bootstrap"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "argocd"
    }

    sync_policy {
      automated {
        prune       = false
        allow_empty = false
        self_heal   = false
      }
    }
  }
}
