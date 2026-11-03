ephemeral "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

resource "scaleway_secret" "main" {
  for_each = local.secret_keys_set

  name = basename(each.key)
  path = dirname(each.key)
  type = "key_value"

  tags = ["terraform"]
}

resource "scaleway_secret_version" "v1" {
  for_each = local.secret_keys_set

  secret_id       = scaleway_secret.main[each.key].id
  data_wo         = jsonencode(yamldecode(ephemeral.sops_file.secrets.raw)[each.key])
  data_wo_version = parseint(substr(sha256(jsonencode(yamldecode(file("secrets.sops.yaml"))[each.key])), 0, 8), 16)
}
