#!/usr/bin/env bash
#
# Derives the piraeus snapshot-controller Helm chart revision whose appVersion
# matches the CSI snapshotter version bundled by the longhorn chart, and pins it
# in k8s/bootstrap/0-snapshot-controller.yaml.
#
# Run by Renovate as a postUpgradeTask on the `longhorn` package, so the
# "longhorn" PR always carries a matching snapshot-controller revision.
#
# Fails (exit 1) when the longhorn version bundles a snapshotter tag for which
# no snapshot-controller chart exists yet. A failing post-upgrade task aborts
# that update by default, blocking the longhorn bump until a matching chart is
# published.
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
longhorn_app="${repo_root}/k8s/bootstrap/0-longhorn.yaml"
snapshot_app="${repo_root}/k8s/bootstrap/0-snapshot-controller.yaml"

curl_flags=(-fsSL --connect-timeout 10 --max-time 30)

# --- 1. Current longhorn chart revision (already bumped by Renovate) ------
longhorn_ver="$(awk '/chart: longhorn/{f=1;next} f && /targetRevision:/{sub(/^[ \t]*targetRevision:[ \t]*/,""); sub(/[ \t\r]+$/,""); print; exit}' "$longhorn_app")"
if [ -z "$longhorn_ver" ]; then
  echo "ERROR: could not read longhorn targetRevision from $longhorn_app" >&2
  exit 1
fi

echo "longhorn chart version:              $longhorn_ver"

# --- 2. Snapshotter tag bundled by that longhorn chart ---------------------
# SNAP_TAG_OVERRIDE lets ops/test the failure path without fetching upstream.
values_url="https://raw.githubusercontent.com/longhorn/charts/longhorn-${longhorn_ver}/charts/longhorn/values.yaml"
snap_tag="$(curl "${curl_flags[@]}" "$values_url" |
  awk '
    /^  csi:/{csi=1}
    csi && /^    snapshotter:/{snap=1}
    snap && /^      tag:/{sub(/^[ \t]*tag:[ \t]*/,""); gsub(/[ "\r]/,""); if (tag == "") tag=$0}
    END{ if (tag ~ /./) print tag }
  ')"
fi
if [ -z "$snap_tag" ]; then
  echo "ERROR: could not extract image.csi.snapshotter.tag from $values_url" >&2
  exit 1
fi

echo "bundled csi-snapshotter tag:          $snap_tag"

# --- 3. Newest snapshot-controller chart whose appVersion == snap_tag ------
# Does not depend on sort order: iterate all snapshot-controller tags and keep
# the numerically greatest chart version whose appVersion matches.
piraeus_repo="https://github.com/piraeusdatastore/helm-charts"
tags="$(git ls-remote --tags --refs "$piraeus_repo" 2>/dev/null |
  sed -n 's#.*refs/tags/snapshot-controller-\([0-9][0-9]*\(\.[0-9][0-9]*\)*\)$#\1#p')"

# Returns 0 (true) if dotted-numeric $1 is greater than $2.
ver_gt() {
  local IFS=.; read -ra a <<< "$1"; read -ra b <<< "$2"
  for i in 0 1 2; do
    local aa="${a[$i]:-0}" bb="${b[$i]:-0}"
    if (( aa > bb )); then return 0; elif (( aa < bb )); then return 1; fi
  done
  return 1
}

matched=""
for v in $tags; do
  chart_url="https://raw.githubusercontent.com/piraeusdatastore/helm-charts/snapshot-controller-${v}/charts/snapshot-controller/Chart.yaml"
  appv="$(curl "${curl_flags[@]}" "$chart_url" |
    awk '
      /^appVersion:/{sub(/^[ \t]*appVersion:[ \t]*/,""); gsub(/[ "\r]/,""); if (appv == "") appv=$0}
      END{ if (appv ~ /./) print appv }
    ')"
  if [ "$appv" = "$snap_tag" ]; then
    if [ -z "$matched" ] || ver_gt "$v" "$matched"; then
      matched="$v"
    fi
  fi
done

if [ -z "$matched" ]; then
  echo "FAIL: longhorn ${longhorn_ver} bundles csi-snapshotter ${snap_tag}, but no piraeus" >&2
  echo "      snapshot-controller chart has that appVersion yet." >&2
  echo "      Blocking the longhorn update until a matching chart is published." >&2
  exit 1
fi

echo "matching snapshot-controller chart:   $matched (appVersion: $snap_tag)"

# --- 4. Pin snapshot-controller to the matching revision --------------------
tmp="${snapshot_app}.tmp"
awk -v new_ver="$matched" -v new_tag="$snap_tag" '
  /^  name: snapshot-controller$/ { snap = 1 }
  snap && /^[ \t]*targetRevision:/ {
    printf "      targetRevision: %s # appVersion: %s, same as longhorn.image.csi.snapshotter.tag\n", new_ver, new_tag
    snap = 0
    next
  }
  { print }
' "$snapshot_app" > "$tmp"

# --- 5. Sanity checks --------------------------------------------------------
grep -q '^  name: snapshot-controller$' "$tmp" || { echo "ERROR: $snapshot_app lost its snapshot-controller anchor" >&2; exit 1; }
grep -q "^      targetRevision: ${matched} # appVersion: ${snap_tag}," "$tmp" || { echo "ERROR: failed to apply ${matched}/${snap_tag} to $snapshot_app" >&2; exit 1; }

mv "$tmp" "$snapshot_app"
echo "synced snapshot-controller -> ${matched} (external-snapshotter ${snap_tag})"
