#!/bin/bash

MY_IMAGE_FILE="fat_image.img"
MY_SD_FAT_MNT="$(mktemp --tmpdir=. --directory TMP_SD_FAT_MNT.XXXX)"

dd if=/dev/zero of=${MY_IMAGE_FILE} bs=1M count=10

fdisk ${MY_IMAGE_FILE} <<EOF > /dev/null 2>&1
n
p
1


t
1
0b
w
EOF


MY_LOOP_DEV=$(losetup --show -f ${MY_IMAGE_FILE}) || {
        echo "ERROR"
	rm -Rf ${MY_IMAGE_FILE} ${MY_SD_FAT_MNT}
	exit 1
}

partprobe "${MY_LOOP_DEV}" || {
        echo "ERROR"
        losetup -d ${MY_LOOP_DEV}
	rm -Rf ${MY_IMAGE_FILE} ${MY_SD_FAT_MNT}
        exit 1
}

echo "Verify loop partition 1 exists."
[ -b "${MY_LOOP_DEV}p1" ] || {
        echo "ERROR"
        losetup -d ${MY_LOOP_DEV}
	rm -Rf ${MY_IMAGE_FILE} ${MY_SD_FAT_MNT}
        exit 1
}

echo "Initializing FAT volume in partition 1 of SD card image file."
mkfs -t vfat -F 32 ${MY_LOOP_DEV}p1 > /dev/null || {
        echo "ERROR"
        losetup -d ${MY_LOOP_DEV}
	rm -Rf ${MY_IMAGE_FILE} ${MY_SD_FAT_MNT}
        exit 1
}

echo "Mounting FAT partition of SD card image file."
mount ${MY_LOOP_DEV}p1 ${MY_SD_FAT_MNT} || {
        echo "ERROR"
        losetup -d ${MY_LOOP_DEV}
        rm -Rf ${MY_SD_FAT_MNT} ${MY_TMP_TAR}
        exit 1
}

cp autorun.inf ${MY_SD_FAT_MNT}/
cp -a Docs ${MY_SD_FAT_MNT}/
cp -a Drivers ${MY_SD_FAT_MNT}/
cp LICENSE ${MY_SD_FAT_MNT}/
cp start.html ${MY_SD_FAT_MNT}/

sync
umount ${MY_SD_FAT_MNT}
losetup -d ${MY_LOOP_DEV}
tar -czvf ${MY_IMAGE_FILE}.tgz ${MY_IMAGE_FILE}
rm -Rf ${MY_SD_FAT_MNT}
