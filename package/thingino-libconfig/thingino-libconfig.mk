################################################################################
#
# libconfig
#
################################################################################

THINGINO_LIBCONFIG_VERSION = 1.7.3
THINGINO_LIBCONFIG_SITE = https://github.com/hyperrealm/libconfig/releases/download/v$(THINGINO_LIBCONFIG_VERSION)
THINGINO_LIBCONFIG_SOURCE = libconfig-$(THINGINO_LIBCONFIG_VERSION).tar.gz
THINGINO_LIBCONFIG_LICENSE = LGPL-2.1+
THINGINO_LIBCONFIG_LICENSE_FILES = COPYING.LIB
THINGINO_LIBCONFIG_INSTALL_STAGING = YES
THINGINO_LIBCONFIG_CONF_OPTS = --disable-examples --disable-tests --enable-static

ifneq ($(BR2_INSTALL_LIBSTDCPP),y)
THINGINO_LIBCONFIG_CONF_OPTS += --disable-cxx
endif

$(eval $(autotools-package))
