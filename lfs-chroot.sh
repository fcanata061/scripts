#!/bin/sh
# Script único para gerenciar chroot do LFS
# Uso: ./lfs-chroot.sh {enter|leave|status}

# ===== CONFIGURAÇÕES =====
LFS=/mnt/lfs
CHROOT="/usr/bin/env -i HOME=/root TERM=$TERM PS1='(lfs-chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin:/bin:/sbin"

# Opções extras
TMP_AS_TMPFS=1        # 1 = monta /tmp como tmpfs
COPY_RESOLVCONF=1     # 1 = copia /etc/resolv.conf para rede dentro do chroot

# ===== FUNÇÕES =====
enter_chroot() {
    echo "[+] Montando sistemas..."

    mount --bind /dev $LFS/dev
    mount --bind /dev/pts $LFS/dev/pts
    mount -t proc proc $LFS/proc
    mount -t sysfs sysfs $LFS/sys
    mount -t tmpfs tmpfs $LFS/run

    if [ "$TMP_AS_TMPFS" -eq 1 ]; then
        mount -t tmpfs tmpfs $LFS/tmp
        chmod 1777 $LFS/tmp
    fi

    if [ -h $LFS/dev/shm ]; then
        mkdir -pv $LFS/$(readlink $LFS/dev/shm)
    fi

    if [ "$COPY_RESOLVCONF" -eq 1 ]; then
        cp -L /etc/resolv.conf $LFS/etc/resolv.conf
    fi

    echo "[+] Entrando no chroot..."
    chroot "$LFS" $CHROOT /bin/bash
}

leave_chroot() {
    echo "[+] Desmontando sistemas..."

    if [ "$TMP_AS_TMPFS" -eq 1 ]; then
        umount -v $LFS/tmp
    fi

    umount -v $LFS/dev/pts
    umount -v $LFS/dev
    umount -v $LFS/proc
    umount -v $LFS/sys
    umount -v $LFS/run

    echo "[+] Chroot desmontado com sucesso."
}

status_chroot() {
    echo "[*] Verificando montagens no $LFS..."
    mount | grep "$LFS"
}

# ===== CLI =====
case "$1" in
    enter) enter_chroot ;;
    leave) leave_chroot ;;
    status) status_chroot ;;
    *)
        echo "Uso: $0 {enter|leave|status}"
        exit 1
        ;;
esac
