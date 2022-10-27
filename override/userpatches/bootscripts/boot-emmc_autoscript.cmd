setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if usb start; then run start_usb_autoscript;else run start_emmc_autoscript;fi;'
setenv start_emmc_autoscript 'if ext4load mmc 1 0x08000000 /boot/emmc_autoscript; then autoscr 0x08000000;else if fatload mmc 1 0x08000000 emmc_autoscript; then autoscr 0x08000000;else echo "load emmc_autoscript failed";fi;fi;'
setenv start_usb_autoscript 'if ext4load usb 0 0x08000000 /boot/s905_autoscript; then autoscr 0x08000000;else if fatload usb 0 0x08000000 s905_autoscript; then autoscr 0x08000000;else echo "load s905_autoscript failed";fi;fi;'
saveenv

if ext4load mmc 1 0x01000000 /boot/u-boot.bin; then
    go 0x01000000
else
    if fatload mmc 1 0x01000000 u-boot.bin; then
        go 0x01000000
    else
        echo "load u-boot.bin failed"
    fi
fi