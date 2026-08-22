LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),X18)
# blobs 全部通过 PRODUCT_COPY_FILES 安装，此处无需额外模块。
endif
