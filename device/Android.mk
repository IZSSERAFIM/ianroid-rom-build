LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),ios6737t)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
