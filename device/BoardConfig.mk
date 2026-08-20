#
# BoardConfig for ios6737t  (MT6737T clone device, "cenon" ios6737t_36_a_n)
#
# 所有数值均来自本机实测，而非照抄同芯片机型：
#   - 加载地址取自 stock recovery.img 的 boot header
#   - 分区大小取自 /proc/partitions 与 by-name 映射
#   - cmdline 取自 /proc/cmdline
#   - sysfs 路径逐个在设备上验证过存在
#

LOCAL_PATH := device/ianroid/ios6737t

TARGET_BOARD_PLATFORM := mt6737t
TARGET_BOOTLOADER_BOARD_NAME := ios6737t_36_a_n
TARGET_NO_BOOTLOADER := true

# Architecture —— 本机 ro.product.cpu.abilist64 为空，是纯 32 位，不能用 arm64
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a53
TARGET_CPU_SMP := true

ARCH_ARM_HAVE_NEON := true
ARCH_ARM_HAVE_VFP := true
ARCH_ARM_HAVE_TLS_REGISTER := true

# Kernel —— 使用本机 stock 内核（含 st7703 屏驱动 + gt1x 触摸驱动）
# 该厂商从未公开内核源码，因此只能以 prebuilt 方式引入。
TARGET_PREBUILT_KERNEL := $(LOCAL_PATH)/kernel

BOARD_KERNEL_BASE     := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET   := 0x00008000
BOARD_RAMDISK_OFFSET  := 0x04000000
BOARD_TAGS_OFFSET     := 0x0E000000
BOARD_KERNEL_CMDLINE  := bootopt=64S3,32N2,32N2 androidboot.selinux=permissive
BOARD_MKBOOTIMG_ARGS  := --kernel_offset $(BOARD_KERNEL_OFFSET) \
                         --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
                         --tags_offset $(BOARD_TAGS_OFFSET)

# Partitions —— 实测 mmcblk0p7 / p8 均为 16MiB
BOARD_BOOTIMAGE_PARTITION_SIZE     := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 2625634304
BOARD_CACHEIMAGE_PARTITION_SIZE    := 419430400
BOARD_FLASH_BLOCK_SIZE             := 131072
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE  := ext4
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true

BOARD_SUPPRESS_EMMC_WIPE   := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_USES_MMCUTILS := true

# ---------------------------------------------------------------------------
# TWRP
# ---------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(LOCAL_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
RECOVERY_GRAPHICS_USE_LINELENGTH := true

# 本机屏幕物理倒装：原厂系统靠 build.prop 里的 ro.sf.hwrotation=180 在
# SurfaceFlinger 层补偿。TWRP 直写 framebuffer 不读该属性，实测画面上下颠倒
# （/sys/class/graphics/fb0/rotate 写入被 MTK 驱动忽略，无运行时解法），
# 因此必须在编译期用 TW_ROTATION 修正。
TW_ROTATION := 180

# 屏幕 720x1498，density 320
TW_THEME := portrait_hdpi

# 以下 sysfs 路径均已在本机 adb 下确认存在
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_SECONDARY_BRIGHTNESS_PATH := /sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_CUSTOM_CPU_TEMP_PATH := /sys/devices/virtual/thermal/thermal_zone1/temp
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/class/android_usb/android0/f_mass_storage/lun/file

TW_INCLUDE_CRYPTO := false
TW_EXCLUDE_SUPERSU := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_FUSE_EXFAT := true
TARGET_USES_EXFAT := true
TW_INCLUDE_FB2PNG := true
TWRP_INCLUDE_LOGCAT := true
TW_DEFAULT_LANGUAGE := zh_CN
TW_NO_REBOOT_BOOTLOADER := false
TW_HAS_DOWNLOAD_MODE := true
TW_USE_TOOLBOX := true
TW_IGNORE_MAJOR_AXIS_0 := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_CHARGER_SHOW_PERCENTAGE := true
BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_15x24.h\"

# 外置 SD 卡（卡槽存在于 msdc1，未插卡时该节点不出现）
RECOVERY_SDCARD_ON_DATA := true
TW_ALLOW_PARTITION_SDCARD := true
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"

HAVE_SELINUX := true
