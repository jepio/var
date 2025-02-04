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

diff_flatcar() {
  local v1=$1
  local v2=$2
  local channel=stable
  local arch=amd64-usr
  local base=https://$channel.release.flatcar-linux.net/${arch}
  diff -up <(curl $base/$v1/flatcar_production_image_packages.txt) <(curl $base/$v2/flatcar_production_image_packages.txt)
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
  case $channel in
    stable|beta|alpha|lts)
      channel="$channel.release"
      ;;
    *)
      arch="images/${arch%-usr}"
  esac
  local base=https://$channel.flatcar-linux.net/${arch}/${version}
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

img_2210="Canonical:0001-com-ubuntu-server-kinetic:22_10:latest"
img_2204="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
img_2304="Canonical:0001-com-ubuntu-server-lunar:23_04-gen2:latest"
img_cvm_2204="Canonical:0001-com-ubuntu-confidential-vm-jammy:22_04-lts-cvm:latest"

az_cvm() {
  if [ -z "${g}" ]; then
    echo >&2 "\$g is not set"
    return 1
  fi
  local n="${1}"
  az vm create --size Standard_DC2as_v5 -g "${g}" -n "${n}" --image "${img_cvm_2204}" --security-type ConfidentialVM --os-disk-security-encryption-type vmgueststateonly --enable-vtpm true --enable-secure-boot false
}

butane() {
  docker run --rm -i quay.io/coreos/butane "$@"
}
