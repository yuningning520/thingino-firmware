$(info --------------------------------------------------------- this is external.mk)

ifneq ($(BR2_SOC_INGENIC_DUMMY),y)
# include makefiles from packages
# include $(sort $(wildcard $(BR2_EXTERNAL)/package/*/*.mk))
include $(sort $(wildcard $(BR2_EXTERNAL_THINGINO_PATH)/package/*/*.mk))
endif

include $(BR2_EXTERNAL_THINGINO_PATH)/thingino-extra.mk
