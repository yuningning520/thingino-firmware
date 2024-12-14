# libschrift.mk
LIBSCHRIFT_SITE_METHOD = git
LIBSCHRIFT_SITE = https://github.com/tomolt/libschrift
LIBSCHRIFT_SITE_BRANCH = master
LIBSCHRIFT_VERSION = $(shell git ls-remote $(LIBSCHRIFT_SITE) $(LIBSCHRIFT_SITE_BRANCH) | head -1 | cut -f1)

LIBSCHRIFT_INSTALL_STAGING = YES
LIBSCHRIFT_INSTALL_TARGET = NO

define LIBSCHRIFT_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) -std=c99 -pedantic -Wall -Wextra -Wconversion -c -o $(@D)/schrift.o $(@D)/schrift.c
	$(TARGET_AR) rc $(@D)/libschrift.a $(@D)/schrift.o
	$(TARGET_RANLIB) $(@D)/libschrift.a
endef

define LIBSCHRIFT_INSTALL_STAGING_CMDS
	$(INSTALL) -m 0755 -D $(@D)/libschrift.a $(STAGING_DIR)/usr/lib/libschrift.a
	$(INSTALL) -m 0644 -D $(@D)/schrift.h $(STAGING_DIR)/usr/include/schrift.h
endef

$(eval $(generic-package))
