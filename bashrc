azure_up() {
  local prefix=${1%/}
  local file=$2
  if [ -n "$prefix" ]; then
    prefix="$prefix/"
  fi
  if [ ! -f "$2" ]; then
    echo >&2 "$2 doesn't exist"
    return 1
  fi
  if [ -z "$SAS_TOKEN" ]; then
    echo >&2 "SAS token missing"
    return 1
  fi
  echo "uploading $prefix$file"
  curl --progress-bar -X PUT -T "$file" -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" \
    "https://jepio.blob.core.windows.net/flatcar-arm64/$prefix$file?$SAS_TOKEN" | cat
}

fetch_flatcar() {
  local channel=$1
  local machine=$(uname -m)
  local arch=
  if [[ ${machine} = "aarch64" ]]; then
    arch=arm64-usr
  elif [[ ${machine} = "x86_64" ]]; then
    arch=amd64-usr
  fi
  local base=https://$channel.release.flatcar-linux.net/${arch}/current
  wget $base/flatcar_production_qemu.sh
  wget $base/flatcar_production_qemu_image.img.bz2
  chmod +x flatcar_production_qemu.sh
}

fetch_alpha() {
  fetch_flatcar alpha
}
fetch_stable() {
  fetch_flatcar stable
}
