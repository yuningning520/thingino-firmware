LIBAUDIOSHIM_SITE_METHOD = git
LIBAUDIOSHIM_SITE = https://github.com/gtxaspec/libaudioshim
LIBAUDIOSHIM_SITE_BRANCH = master
LIBAUDIOSHIM_VERSION = $(shell git ls-remote $(LIBAUDIOSHIM_SITE) $(LIBAUDIOSHIM_SITE_BRANCH) | head -1 | cut -f1)
LIBAUDIOSHIM_INSTALL_STAGING = YES

LIBAUDIOSHIM_LICENSE = GPL-2.0
LIBAUDIOSHIM_LICENSE_FILES = COPYING

define LIBAUDIOSHIM_BUILD_CMDS
	$(TARGET_CC) -Wall -Os -fPIC -c $(@D)/audioshim.c -o $(@D)/audioshim.o
	$(TARGET_CC) -shared -Wl,--version-script=$(@D)/shim.map -Wl,--export-dynamic -fvisibility=hidden -fno-common -o $(@D)/libaudioshim.so $(@D)/audioshim.o

endef

define LIBAUDIOSHIM_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libaudioshim.so $(STAGING_DIR)/usr/lib/libaudioshim.so
endef

define LIBAUDIOSHIM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libaudioshim.so $(TARGET_DIR)/usr/lib/libaudioshim.so
endef

$(eval $(generic-package))
