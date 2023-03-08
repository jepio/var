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

fetch_flatcar_uefi() {
  local channel=$1
  local version=${2:-current}

  local machine=$(uname -m)
  local arch=
  if [[ ${machine} = "aarch64" ]]; then
    arch=arm64-usr
  elif [[ ${machine} = "x86_64" ]]; then
    arch=amd64-usr
  fi
  local base=https://$channel.release.flatcar-linux.net/${arch}/${version}
  wget $base/flatcar_production_qemu_uefi.sh
  wget $base/flatcar_production_qemu_uefi_image.img.bz2
  wget $base/flatcar_production_qemu_uefi_efi_vars.fd
  wget $base/flatcar_production_qemu_uefi_efi_code.fd
  chmod +x flatcar_production_qemu_uefi.sh
}

fetch_flatcar() {
  local channel=$1
  local version=${2:-current}

  local machine=$(uname -m)
  local arch=
  if [[ ${machine} = "aarch64" ]]; then
    arch=arm64-usr
  elif [[ ${machine} = "x86_64" ]]; then
    arch=amd64-usr
  fi
  local base=https://$channel.release.flatcar-linux.net/${arch}/${version}
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
ct() {
  docker run -i --rm ghcr.io/flatcar-linux/ct "$@"
}

sshu() {
  ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null "$@"
}
