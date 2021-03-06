#!/bin/sh -e

APP_DIR=/usr/lib/tmpusb-zfs-passphrase
IRF_DIR=/usr/share/initramfs-tools/scripts

if [ -t 1 ]; then
    ANSI_RESET='\e[0m'
    ANSI_RED='\e[31m'
    ANSI_GREEN='\e[32m'
    ANSI_CYAN='\e[36m'
fi

if ! [ -e $IRF_DIR/zfs ]; then
    echo "${ANSI_RED}Cannot find ZFS initramfs-tools script${ANSI_RESET}" >&2
    exit 1
fi

if grep -q 'KEYLOCATION=prompt' $IRF_DIR/zfs; then
    echo "ZFS initramfs script [${ANSI_GREEN}OK${ANSI_RESET}]"
    exit 0
else
    echo "ZFS initramfs script [${ANSI_CYAN}UPDATE${ANSI_RESET}]"

    cp $APP_DIR/initramfs/init-premount $IRF_DIR/init-premount/tmpusb
    cp $APP_DIR/initramfs/init-bottom $IRF_DIR/init-bottom/tmpusb
    chmod 755 $IRF_DIR/init-premount/tmpusb
    chmod 755 $IRF_DIR/init-bottom/tmpusb

    mkdir -p $APP_DIR/backup/
    cp $IRF_DIR/zfs $APP_DIR/backup/zfs

    if grep -q 'If root dataset is encrypted...' $IRF_DIR/zfs; then
        sed -i 's/load-key/load-key -L prompt/' $IRF_DIR/zfs
        sed -i '0,/load-key/ {s/-L prompt//}' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\t$ZFS load-key "${ENCRYPTIONROOT}"' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\tTPOOLS=`$ZPOOL import | grep "^   pool:" | cut -d: -f2`' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\tfor TPOOL in $TPOOLS; do' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\t\t$ZPOOL import $TPOOL' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\t\t$ZFS load-key $TPOOL' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\tdone' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i \\t\t\tKEYLOCATION=prompt' $IRF_DIR/zfs
        sed -i '/KEYSTATUS=/i\\' $IRF_DIR/zfs
        if update-initramfs -u; then
            echo "ZFS initramfs script update [${ANSI_GREEN}OK${ANSI_RESET}]"
            exit 0
        else
            echo "ZFS initramfs script update [${ANSI_RED}NOK${ANSI_RESET}]"
        fi
    else
        echo "ZFS initramfs script [${ANSI_RED}UNKNOWN${ANSI_RESET}]"
    fi
fi

exit 1
