#!/usr/bin/env bash
# Update SCALE tarball sources in manifest.nix.
#
#   update.sh [-d|-b] (updates both to latest)
#   update.sh [-d|-b] latest [version]
#   update.sh [-d|-b] nightly [commit]
#
#   -d, --download  download tarball into the store if missing
#   -b, --build     build updated packages, revert if build fails; implies -d
#
set -euo pipefail

root="$(dirname "$(realpath "$0")")"
until [[ -e "$root/flake.nix" ]]; do
  [[ "$root" != / ]] || { echo "flake root not found" >&2; exit 1; }
  root="$(dirname "$root")"
done
manifest="$root/nix/lib/manifest.nix"
download=false
build=false
curl_args=()
channel=""
color=""

if [[ -t 2 ]]; then
  bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m'
  red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' blue=$'\e[34m' magenta=$'\e[35m'
else
  bold="" dim="" reset="" red="" green="" yellow="" blue="" magenta=""
fi

bullet=$'\u2022' check=$'\u2713' cross=$'\u2717' arrow=$'\u2192'

# _log <symbol> <message>
_log() {
  printf '%s%-7s%s %s %s\n' "$bold$color" "$channel" "$reset" "$1" "${*:2}" >&2
}

log() {
  _log "${dim}${bullet}${reset}" "$@"
}

ok() {
  _log "${green}${check}${reset}" "$@"
}

warn() {
  _log "${yellow}!${reset}" "${yellow}$*${reset}"
}

die() {
  _log "${red}${cross}${reset}" "${red}$*${reset}"
  exit 1
}

# changed <old> <new>
changed() {
  ok "${dim}$1${reset} ${arrow} ${bold}${green}$2${reset}"
}

fetch() {
  curl -fsSL "${curl_args[@]}" "$@"
}

# set_attr <block> <key> <value>
# replace `key = "...";` within a top-level block
set_attr() {
  sed -i -E "/^  $1 =/,/^  };/ s|^( +$2 = )\"[^\"]*\";|\1\"$3\";|" "$manifest"
}

get_attr() {
  nix eval --raw --file "$manifest" "$1"
}

sri() {
  echo "sha512-$(xxd -r -p <<<"$1" | base64 -w0)"
}

# store_file <name> <url> <sha512>
# check the tarball is in the store, download it with -d
store_file() {
  local path tmp
  path="$(nix-store --print-fixed-path sha512 "$3" "$1")"

  if nix-store --check-validity "$path" 2>/dev/null; then
    ok "already in store ${dim}$path${reset}"
  elif $download; then
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" EXIT
    log "downloading ${dim}$2${reset}"
    curl -fL --progress-bar "${curl_args[@]}" -o "$tmp/$1" "$2"
    nix-store --add-fixed sha512 "$tmp/$1" >/dev/null
    rm -rf "$tmp"
    ok "added to store ${dim}$path${reset}"
  else
    warn "not in store, rerun with --download to fetch it"
  fi
}

update_latest() {
  local base="https://pkgs.scale-lang.com/tar"
  local releases version platform name sha512 old
  channel=latest color="$blue"

  log "fetching release index"
  releases="$(fetch "$base/" |
    sed -nE 's|.*href="scale-([0-9.]+)-([A-Za-z0-9_]+)\.tar\.xz".*|\1 \2|p' |
    sort -V)"
  version="${1:-$(tail -n1 <<<"$releases" | cut -d' ' -f1)}"

  # the platform suffix differs between releases (amd64, Linux)
  platform="$(awk -v v="$version" '$1 == v { print $2 }' <<<"$releases")"
  [[ -n "$platform" ]] ||
    die "$version not found, available:" $(cut -d' ' -f1 <<<"$releases")

  name="scale-$version-$platform.tar.xz"
  log "selected $name"
  sha512="$(fetch "$base/$name.sha512" | cut -d' ' -f1)"

  if $download; then
    store_file "$name" "$base/$name" "$sha512"
  fi

  old="$(get_attr latest.version)"
  if [[ "$old" == "$version" ]]; then
    ok "up to date ${dim}($version)${reset}"
    return
  fi

  set_attr latest version "$version"
  set_attr latest platform "$platform"
  set_attr latest hash "$(sri "$sha512")"
  changed "$old" "$version"
}

cf_token() {
  local cloudflared=(cloudflared)
  type -P cloudflared >/dev/null || cloudflared=(nix run nixpkgs#cloudflared --)

  "${cloudflared[@]}" access token -app="$1" 2>/dev/null && return
  log "logging in to Cloudflare Access"
  "${cloudflared[@]}" access login "$1" >&2
  "${cloudflared[@]}" access token -app="$1"
}

# list <url>: "<mtime> <name>"
# for each entry of a caddy file_server listing
list() {
  fetch -H 'Accept: application/json' "$1" |
    sed 's/},{/}\n{/g' |
    sed -nE 's/.*"name":"([^"]*)".*"mod_time":"([^"]*)".*/\2 \1/p'
}

update_nightly() {
  local base="https://dev-artifacts.spectralcompute.com/external/nightlies"
  local commits commit name="" url sha512 old
  channel=nightly color="$magenta"
  curl_args=(-H "cf-access-token: ${CF_ACCESS_TOKEN:-$(cf_token "$base/")}")

  log "listing nightlies"
  commits="${1:-$(list "$base/" | sort -r | sed -nE 's|.* ([0-9a-f]{40})/$|\1|p')}"

  # not every commit has a linux build..
  # look for the newest one that does
  for commit in $commits; do
    name="$(list "$base/$commit/linux/" 2>/dev/null |
      grep -oE 'scale-unstable-[0-9.]+-Linux\.tar\.xz$' | head -n1)" && break
  done
  [[ -n "$name" ]] || die "no linux nightly found"

  url="$base/$commit/linux/$name"
  log "selected $name ${dim}(${commit:0:12})${reset}"
  sha512="$(fetch "$url.sha512" | cut -d' ' -f1)"

  # requireFile expects the tarball to be in the store already
  store_file "$name" "$url" "$sha512"

  old="$(get_attr nightly.version)"
  if [[ "$(get_attr nightly.source.url)" == "$url" ]]; then
    ok "up to date ${dim}($old)${reset}"
    return
  fi

  set_attr nightly commitHash "$commit"
  set_attr nightly commitDate "$(sed -E 's/scale-unstable-(.*)-Linux\.tar\.xz/\1/' <<<"$name")"
  set_attr nightly hash "$(sri "$sha512")"
  changed "$old" "$(get_attr nightly.version)"
}

# update <channel> [args]
# run update_<channel>, then build it with -b
update() {
  local before attr pkgs
  before="$(<"$manifest")"
  "update_$1" "${@:2}"

  $build || return 0

  attr="scalePackages$([[ "$1" == latest ]] || echo "_$1")"
  pkgs="$(nix eval --raw "$root#$attr" 2>/dev/null --apply \
    's: toString (builtins.filter (n: (s.${n}.type or null) == "derivation") (builtins.attrNames s))')"

  log "building $attr ${dim}($pkgs)${reset}"
  if nix build --no-link $(printf "$root#$attr.%s " $pkgs); then
    ok "build succeeded"
  elif [[ "$(<"$manifest")" != "$before" ]]; then
    printf '%s\n' "$before" >"$manifest"
    die "build failed, update reverted"
  else
    die "build failed"
  fi
}

args=()
for arg; do
  case "$arg" in
    -d | --download) download=true ;;
    -b | --build) build=true download=true ;;
    *) args+=("$arg") ;;
  esac
done
set -- "${args[@]}"

case "${1:-}" in
  latest | nightly)
    update "$@"
    ;;
  "")
    update latest
    update nightly
    ;;
  *)
    echo "usage: $0 [-d|-b] [latest [version] | nightly [commit]]" >&2
    exit 1
    ;;
esac
