# DO NOT EDIT THIS FILE
#
# Please edit /boot/armbianEnv.txt to set supported parameters
#

setenv scriptaddr "0x32000000"
setenv kernel_addr_r "0x34000000"
setenv fdt_addr_r "0x4080000"
setenv overlay_error "false"
# default values
setenv rootdev "/dev/mmcblk1p1"
setenv verbosity "1"
setenv console "both"
setenv bootlogo "false"
setenv rootfstype "ext4"
setenv docker_optimizations "on"

setenv devtype "mmc"
setenv devnum 1
setenv prefix "/boot/"

if usb start; then
    if test -e usb 0 ${prefix}u-boot.bin; then
        echo "found usb 0 ${prefix}u-boot.bin"
        setenv devtype "usb"
        setenv devnum 0
    else
        if test -e usb 0 /u-boot.bin; then
            echo "found usb 0 /u-boot.bin"
            setenv devtype "usb"
            setenv devnum 0
            setenv prefix "/"
        else
            echo "Not found u-boot.bin"
        fi
    fi
else
    echo "No USB boot device"
fi

echo "devtype: ${devtype}"
echo "devnum: ${devnum}"
echo "prefix: ${prefix}"

# Show what uboot default fdtfile is
echo "U-boot default fdtfile: ${fdtfile}"
echo "Current variant: ${variant}"

if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
    echo "load ${devtype} ${devnum} ${scriptaddr} ${prefix}armbianEnv.txt"
    load ${devtype} ${devnum} ${scriptaddr} ${prefix}armbianEnv.txt
    env import -t ${scriptaddr} ${filesize}
    echo "Current fdtfile after armbianEnv: ${fdtfile}"
else
    echo "Not found armbianEnv.txt"
fi

echo "Current ethaddr: ${ethaddr}"

# get PARTUUID of first partition on SD/eMMC it was loaded from
# mmc 0 is always mapped to device u-boot (2016.09+) was loaded from
if test "${devtype}" = "mmc"; then part uuid mmc ${devnum}:1 partuuid; fi

if test -e ${devtype} ${devnum} ${prefix}uInitrd; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found uInitrd"
fi

if test -e ${devtype} ${devnum} ${prefix}Image; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found Image"
fi

if test -e ${devtype} ${devnum} ${prefix}dtb/${fdtfile}; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found DTB"
fi

if test "${bootfileexist}" = "true"; then
    if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
    if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
    if test "${bootlogo}" = "true"; then
        setenv consoleargs "splash plymouth.ignore-serial-consoles ${consoleargs}"
    else
        setenv consoleargs "splash=verbose ${consoleargs}"
    fi

    setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} ubootpart=${partuuid} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
    if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
    echo "Mainline bootargs: ${bootargs}"

    echo "load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd"
    load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd

    echo "load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}Image"
    load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}Image

    echo "load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}"
    load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
    fdt addr ${fdt_addr_r}
    fdt resize 65536

    for overlay_file in ${overlays}; do
        if load ${devtype} ${devnum} ${scriptaddr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
            echo "Applying kernel provided DT overlay ${overlay_prefix}-${overlay_file}.dtbo"
            fdt apply ${scriptaddr} || setenv overlay_error "true"
        fi
    done

    for overlay_file in ${user_overlays}; do
        if load ${devtype} ${devnum} ${scriptaddr} ${prefix}overlay-user/${overlay_file}.dtbo; then
            echo "Applying user provided DT overlay ${overlay_file}.dtbo"
            fdt apply ${scriptaddr} || setenv overlay_error "true"
        fi
    done

    if test "${overlay_error}" = "true"; then
        echo "Error applying DT overlays, restoring original DT"
        load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
    else
        if load ${devtype} ${devnum} ${scriptaddr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-fixup.scr; then
            echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
            source ${scriptaddr}
        fi
        if test -e ${devtype} ${devnum} ${prefix}fixup.scr; then
            load ${devtype} ${devnum} ${scriptaddr} ${prefix}fixup.scr
            echo "Applying user provided fixup script (fixup.scr)"
            source ${scriptaddr}
        fi
    fi

    booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
fi

# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
