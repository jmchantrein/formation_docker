#!/usr/bin/env bash
# Rejoue les commandes non interactives du cours Virtualisation et relève les versions des outils,
# pour remplacer les sorties types des diapositives par des sorties réelles.
# Usage, sur un hôte Linux avec KVM : ./rejouer-tp.sh > sorties.txt
set -u
run() { printf '\n$ %s\n' "$1"; bash -c "$1" 2>&1; }

echo "# $(date -I) · $(uname -srm)"
run 'qemu-system-x86_64 --version | head -1'
run 'qemu-img --version | head -1'
run 'virsh --version'
run 'virt-install --version'
run 'sha256sum --version | head -1'
run 'gpgv --version | head -1'
run "lscpu | grep -E 'Virtualization|Virtualisation'"
run "grep -cE 'vmx|svm' /proc/cpuinfo"
run 'ls /sys/module | grep kvm'
run "stat -c '%A %U %G %n' /dev/kvm"
run 'cat /sys/module/kvm_intel/parameters/nested 2>/dev/null || cat /sys/module/kvm_amd/parameters/nested'
dossier=$(mktemp -d)
run "cd $dossier && qemu-img create -q -f qcow2 debian.qcow2 20G && ls -sh debian.qcow2"
rm -rf "$dossier"
for accel in tcg kvm; do
  run "printf 'info kvm\nquit\n' | qemu-system-x86_64 -accel $accel -m 1024 -display none -monitor stdio -nodefaults | tr -d '\r' | grep '^kvm support'"
done
printf '\n# Dans la VM Debian (question 5) : systemd-detect-virt ; lspci | grep -i virtio\n'
printf '# Dans la VM Alpine (question 6) : dmesg | grep -i hypervisor\n'
