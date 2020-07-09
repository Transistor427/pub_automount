#!/bin/bash
# Этот сценарий вызывается из системного юнита как сценарий обработки подключения/отключения накопителей.
usage() {
    echo "Использование: $0 {add|remove} device_name (например, sdb1)"
    exit 1
}
if [[ $# -ne 2 ]]; then
    usage 
fi
ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"
# Проверяем, не примонтировано ли уже устройство
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')
do_mount() {
    if [[ -n ${MOUNT_POINT} ]]; then
        echo "Предупреждение: ${DEVICE} уже смонтировано в ${MOUNT_POINT}"
        exit 1
    fi
# Получаем информацию об устройстве : метка $ID_FS_LABEL, идентификатоп $ID_FS_UUID, и тип файловой системы $ID_FS_TYPE
    eval $(/sbin/blkid -o udev ${DEVICE})
# Создаём точку монтирования:
    LABEL=${ID_FS_LABEL}
    if [[ -z "${LABEL}" ]]; thenapt-get update && apt-get upgrade
        LABEL=${DEVBASE}
    elif /bin/grep -q " /home/pi/.octoprint/uploads/${LABEL} " /etc/mtab; then
# Если точка монтирования уже существует изменяем имя:
        LABEL+="-${DEVBASE}"
    fi 
MOUNT_POINT="/home/pi/.octoprint/uploads/${LABEL}"
     echo "Точка монтирования: ${MOUNT_POINT}"
    /bin/mkdir -p ${MOUNT_POINT}
# Глобальные опции монтирования
    OPTS="rw,relatime"
# Специфические опции монтирования:
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
    fi
    if ! /bin/mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        echo "Ошибка монтирования ${DEVICE} (статус = $?)" 
        /bin/rmdir ${MOUNT_POINT}
        exit 1
    fi
    echo "**** Устройство ${DEVICE} смонтировано в ${MOUNT_POINT} ****" 
}
do_unmount() { 
    if [[ -z ${MOUNT_POINT} ]]; then
        echo "Предупреждение: ${DEVICE} не смонтировано"
    else
        /bin/umount -l ${DEVICE}
        echo "**** Отмонтировано ${DEVICE}"
    fi
# Удаление пустых каталогов
    for f in /home/pi/.octoprint/uploads/* ; do
        if [[ -n $(/usr/bin/find "$f" -maxdepth 0 -type d -empty) ]]; then
            if ! /bin/grep -q " $f " /etc/mtab; then 
                echo "**** Удаление точки монтирования $f"
                /bin/rmdir "$f" 
            fi
        fi
    done
}
case "${ACTION}" in
    add) do_mount ;; 
    remove) do_unmount ;; 
    *) usage ;; 
esac
