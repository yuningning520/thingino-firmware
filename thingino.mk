# Thingino Firmware
# https://github.com/themactep/thingino-firmware

ifeq ($(__BASH_MAKE_COMPLETION__),1)
	exit
endif

$(info -------------------------------- Checking prerequisites)

ifneq ($(shell command -v gawk >/dev/null; echo $$?),0)
$(error Please run `make bootstrap` to install prerequisites.)
endif

ifneq ($(findstring $(empty) $(empty),$(CURDIR)),)
$(error Current directory path "$(CURDIR)" contains spaces. Please remove spaces from the path and try again.)
endif

$(info -------------------------------- Setting up constants)

BR2_EXTERNAL_THINGINO_PATH := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

CHATTY := y

SIZE_32M := 33554432
SIZE_16M := 16777216
SIZE_8M := 8388608
SIZE_256K := 262144
SIZE_128K := 131072
SIZE_64K := 65536
SIZE_32K := 32768
SIZE_16K := 16384
SIZE_8K := 8192
SIZE_4K := 4096

ALIGN_BLOCK := $(SIZE_32K)

U_BOOT_GITHUB_URL := https://github.com/gtxaspec/u-boot-ingenic/releases/download/latest

ifeq ($(shell command -v figlet),)
FIGLET := echo
else
FIGLET := $(shell command -v figlet) -t -f pagga
endif

WGET := wget --quiet --no-verbose --retry-connrefused --continue --timeout=5

SCRIPTS_DIR := $(BR2_EXTERNAL_THINGINO_PATH)/scripts

$(info -------------------------------- Setting up environment)

# Camera IP address
# shortened to just IP for convenience of running from command line
IP ?= 192.168.1.10
CAMERA_IP_ADDRESS = $(IP)

# TFTP server IP address to upload compiled images to
TFTP_IP_ADDRESS ?= 192.168.1.254

# Device of SD card
SDCARD_DEVICE ?= /dev/sdf

# Buildroot downloads directory
# can be reused from environment, just export the value:
# export BR2_DL_DIR = /path/to/your/local/storage
BR2_DL_DIR ?= $(BR2_EXTERNAL_THINGINO_PATH)/../downloads

# directory for extracting Buildroot sources
SRC_DIR ?= $(HOME)/src

# working directory
OUTPUT_DIR ?= $(HOME)/output/$(BOARD)
STDOUT_LOG ?= $(OUTPUT_DIR)/compilation.log
STDERR_LOG ?= $(OUTPUT_DIR)/compilation-errors.log

U_BOOT_BIN = $(OUTPUT_DIR)/images/$(patsubst "%",%,$(BR2_TARGET_UBOOT_FORMAT_CUSTOM_NAME))

CONFIG_BIN := $(OUTPUT_DIR)/images/config.jffs2
KERNEL_BIN := $(OUTPUT_DIR)/images/uImage
ROOTFS_BIN := $(OUTPUT_DIR)/images/rootfs.squashfs
ROOTFS_TAR := $(OUTPUT_DIR)/images/rootfs.tar
OVERLAY_BIN := $(OUTPUT_DIR)/images/overlay.jffs2

# create a full binary file suffixed with the time of the last modification to either uboot, kernel, or rootfs
FIRMWARE_NAME_FULL = thingino-$(BOARD).bin
FIRMWARE_NAME_PART = thingino-$(BOARD)-update.bin

FIRMWARE_BIN_FULL = $(OUTPUT_DIR)/images/$(FIRMWARE_NAME_FULL)
FIRMWARE_BIN_PART = $(OUTPUT_DIR)/images/$(FIRMWARE_NAME_PART)

$(info -------------------------------- Defining sizes)

# file sizes
U_BOOT_BIN_SIZE = $(shell stat -c%s $(U_BOOT_BIN))
KERNEL_BIN_SIZE = $(shell stat -c%s $(KERNEL_BIN))
ROOTFS_BIN_SIZE = $(shell stat -c%s $(ROOTFS_BIN))
CONFIG_BIN_SIZE = $(shell stat -c%s $(CONFIG_BIN))
OVERLAY_BIN_SIZE = $(shell stat -c%s $(OVERLAY_BIN))

FIRMWARE_BIN_FULL_SIZE = $(shell stat -c%s $(FIRMWARE_BIN_FULL))
FIRMWARE_BIN_PART_SIZE = $(shell stat -c%s $(FIRMWARE_BIN_PART))

U_BOOT_BIN_SIZE_ALIGNED = $(shell echo $$((($(U_BOOT_BIN_SIZE) + $(ALIGN_BLOCK) - 1) / $(ALIGN_BLOCK) * $(ALIGN_BLOCK))))
CONFIG_BIN_SIZE_ALIGNED = $(shell echo $$((($(CONFIG_BIN_SIZE) + $(ALIGN_BLOCK) - 1) / $(ALIGN_BLOCK) * $(ALIGN_BLOCK))))
KERNEL_BIN_SIZE_ALIGNED = $(shell echo $$((($(KERNEL_BIN_SIZE) + $(ALIGN_BLOCK) - 1) / $(ALIGN_BLOCK) * $(ALIGN_BLOCK))))
ROOTFS_BIN_SIZE_ALIGNED = $(shell echo $$((($(ROOTFS_BIN_SIZE) + $(ALIGN_BLOCK) - 1) / $(ALIGN_BLOCK) * $(ALIGN_BLOCK))))
OVERLAY_BIN_SIZE_ALIGNED = $(shell echo $$((($(OVERLAY_BIN_SIZE) + $(ALIGN_BLOCK) - 1) / $(ALIGN_BLOCK) * $(ALIGN_BLOCK))))

# fixed size partitions
U_BOOT_PARTITION_SIZE := $(SIZE_256K)
U_BOOT_ENV_PARTITION_SIZE := $(SIZE_64K)
CONFIG_PARTITION_SIZE := $(SIZE_64K)
KERNEL_PARTITION_SIZE = $(KERNEL_BIN_SIZE_ALIGNED)
ROOTFS_PARTITION_SIZE = $(ROOTFS_BIN_SIZE_ALIGNED)

FIRMWARE_FULL_SIZE = $(FLASH_SIZE)
FIRMWARE_PART_SIZE = $(shell echo $$(($(FLASH_SIZE) - $(U_BOOT_PARTITION_SIZE) - $(U_BOOT_ENV_PARTITION_SIZE))))

# dynamic partitions
OVERLAY_PARTITION_SIZE = $(shell echo $$(($(FLASH_SIZE) - $(OVERLAY_OFFSET))))
OVERLAY_LLIMIT = $(shell echo $$(($(ALIGN_BLOCK) * 5)))

# partition offsets
U_BOOT_OFFSET := 0
U_BOOT_ENV_OFFSET = $(shell echo $$(($(U_BOOT_OFFSET) + $(U_BOOT_PARTITION_SIZE))))
#CONFIG_OFFSET = $(shell echo $$(($(U_BOOT_ENV_OFFSET) + $(U_BOOT_ENV_PARTITION_SIZE))))
#KERNEL_OFFSET = $(shell echo $$(($(CONFIG_OFFSET) + $(CONFIG_PARTITION_SIZE))))
KERNEL_OFFSET = $(shell echo $$(($(U_BOOT_ENV_OFFSET) + $(U_BOOT_ENV_PARTITION_SIZE))))
ROOTFS_OFFSET = $(shell echo $$(($(KERNEL_OFFSET) + $(KERNEL_PARTITION_SIZE))))
OVERLAY_OFFSET = $(shell echo $$(($(ROOTFS_OFFSET) + $(ROOTFS_PARTITION_SIZE))))
# special case with no uboot nor env
OVERLAY_OFFSET_PART = $(shell echo $$(($(KERNEL_PARTITION_SIZE) + $(ROOTFS_PARTITION_SIZE))))

$(info -------------------------------- Define board)

CAMERA_CONFIG_REAL := $(shell $(SCRIPTS_DIR)/boards.sh $(BOARD))
$(info CAMERA_CONFIG_REAL=$(CAMERA_CONFIG_REAL))

BOARD := $(shell basename $(CAMERA_CONFIG_REAL))
$(info BOARD=$(BOARD))

ifeq ($(BOARD),)
$(error No camera config provided)
else
$(info -------------------------------- Build for BOARD $(BOARD))
endif

$(info -------------------------------- Include $(CAMERA_CONFIG_REAL))
include $(CAMERA_CONFIG_REAL)

#$(info -------------------------------- Include $(OUTPUT_DIR)/.config)
#include $(OUTPUT_DIR)/.config

# BR2_DEFCONFIG ?= $(OUTPUT_DIR)/.config
# BR2_DEFCONFIG ?= $(CAMERA_CONFIG_REAL)

BR2_TARGET_UBOOT_BOARDNAME := $(UBOOT_BOARDNAME)

# make command for buildroot
BR2_MAKE = $(MAKE) V=1 \
	BR2_EXTERNAL=$(BR2_EXTERNAL_THINGINO_PATH) \
	-C ./buildroot O=$(OUTPUT_DIR) \
	BR2_DEFCONFIG=$(OUTPUT_DIR)/$(BOARD)_defconfig \
    U_BOOT_ENV_FINAL_TXT=$(OUTPUT_DIR)/uenv.txt

.PHONY: all bootstrap compile compile_fast menuconfig nconfig saveconfig update \
	build clean cleanbuild compile_config \
	help pack sdk toolchain upload_tftp upgrade_ota br-%

# $(BR2_MAKE) -j$(shell nproc) all
compile: $(OUTPUT_DIR)/.config
	$(info -------------------------------- $@)
	$(BR2_MAKE) all
	$(BR2_MAKE) pack
	@$(FIGLET) "FINE"

$(OUTPUT_DIR)/.config: $(OUTPUT_DIR)/$(BOARD)_defconfig
	$(info -------------------------------- $@)
	$(BR2_MAKE) defconfig

$(OUTPUT_DIR)/$(BOARD)_defconfig:
	$(info -------------------------------- $@)
	$(SCRIPTS_DIR)/board_config.sh $(BOARD)

all: $(SRC_DIR)/.keep $(OUTPUT_DIR)/.keep $(OUTPUT_DIR)/$(BOARD)_defconfig $(OUTPUT_DIR)/uenv.txt compile
	$(info -------------------------------- $@)
	@$(FIGLET) "$(BOARD)"

$(SRC_DIR)/.keep:
	$(info -------------------------------- $@)
	mkdir -p $(SRC_DIR)
	touch $(SRC_DIR)/.keep

$(OUTPUT_DIR)/.keep:
	$(info -------------------------------- $@)
	mkdir -p $(OUTPUT_DIR)
	touch $(OUTPUT_DIR)/.keep

$(OUTPUT_DIR)/uenv.txt: $(OUTPUT_DIR)/.config
	$(info -------------------------------- $@)
	if [ -f $(BR2_EXTERNAL_THINGINO_PATH)$(shell sed -rn "s/^U_BOOT_ENV_TXT=\"\\\$$\(\w+\)(.+)\"/\1/p" $(OUTPUT_DIR)/.config) ]; then \
	sed -E '/^(#|\s*$$)/d' $(BR2_EXTERNAL_THINGINO_PATH)$(shell sed -rn "s/^U_BOOT_ENV_TXT=\"\\\$$\(\w+\)(.+)\"/\1/p" $(OUTPUT_DIR)/.config) | tee $(OUTPUT_DIR)/uenv.txt; fi
	if [ -f $(BR2_EXTERNAL_THINGINO_PATH)/local.uenv.txt ]; then sed -E '/^(#|\s*$$)/d' $(BR2_EXTERNAL_THINGINO_PATH)/local.uenv.txt | tee -a $(OUTPUT_DIR)/uenv.txt; fi










compile_fast:
	$(info -------------------------------- $@)
	$(BR2_MAKE) -j$(shell nproc) all
	$(BR2_MAKE) pack
	@$(FIGLET) "FINE"

# install what's needed
bootstrap:
	$(info -------------------------------- $@)
	$(SCRIPTS_DIR)/dep_check.sh

# update repo and submodules
update:
	$(info -------------------------------- $@)
	git pull --rebase --autostash
	git submodule init
	git submodule update

# call configurator
menuconfig:
	$(info -------------------------------- $@)
	$(BR2_MAKE) menuconfig

nconfig:
	$(info -------------------------------- $@)
	$(BR2_MAKE) nconfig

# permanently save changes to the defconfig
saveconfig:
	$(info -------------------------------- $@)
	$(BR2_MAKE) savedefconfig

### Files

# remove target/ directory
clean:
	$(info -------------------------------- $@)
	rm -rf $(OUTPUT_DIR)/target

# rebuild from scratch
cleanbuild:
	$(info -------------------------------- $@ done)
	if [ -d "$(OUTPUT_DIR)" ]; then rm -rf $(OUTPUT_DIR); fi
	$(BR2_MAKE) all

# assemble final images
pack: $(FIRMWARE_BIN_FULL) $(FIRMWARE_BIN_PART)
	$(info -------------------------------- $@)
	@$(FIGLET) $(BOARD)
	$(info ALIGNMENT: $(ALIGN_BLOCK))
	$(info  )
	$(info $(shell printf "%-7s | %8s | %8s | %8s | %8s | %8s | %8s |" NAME OFFSET PT_SIZE CONTENT ALIGNED END LOSS))
	$(info $(shell printf "%-7s | %8d | %8d | %8d | %8d | %8d | %8d |" U_BOOT $(U_BOOT_OFFSET) $(U_BOOT_PARTITION_SIZE) $(U_BOOT_BIN_SIZE) $(U_BOOT_BIN_SIZE_ALIGNED) $$(($(U_BOOT_OFFSET) + $(U_BOOT_BIN_SIZE_ALIGNED))) $$(($(U_BOOT_PARTITION_SIZE) - $(U_BOOT_BIN_SIZE_ALIGNED))) ))
	$(info $(shell printf "%-7s | %8d | %8d | %8d | %8d | %8d | %8d |" ENV $(U_BOOT_ENV_OFFSET) $(U_BOOT_ENV_PARTITION_SIZE) $(U_BOOT_ENV_BIN_SIZE) $(U_BOOT_ENV_BIN_SIZE_ALIGNED) $$(($(U_BOOT_ENV_OFFSET) + $(U_BOOT_ENV_BIN_SIZE_ALIGNED))) $$(($(U_BOOT_ENV_PARTITION_SIZE) - $(U_BOOT_ENV_BIN_SIZE_ALIGNED))) ))
	$(info $(shell printf "%-7s | %8d | %8d | %8d | %8d | %8d | %8d |" KERNEL $(KERNEL_OFFSET) $(KERNEL_PARTITION_SIZE) $(KERNEL_BIN_SIZE) $(KERNEL_PARTITION_SIZE) $$(($(KERNEL_OFFSET) + $(KERNEL_PARTITION_SIZE))) $$(($(KERNEL_PARTITION_SIZE) - $(KERNEL_PARTITION_SIZE))) ))
	$(info $(shell printf "%-7s | %8d | %8d | %8d | %8d | %8d | %8d |" ROOTFS $(ROOTFS_OFFSET) $(ROOTFS_PARTITION_SIZE) $(ROOTFS_BIN_SIZE) $(ROOTFS_PARTITION_SIZE) $$(($(ROOTFS_OFFSET) + $(ROOTFS_PARTITION_SIZE))) $$(($(ROOTFS_PARTITION_SIZE) - $(ROOTFS_PARTITION_SIZE))) ))
	$(info $(shell printf "%-7s | %8d | %8d | %8d | %8d | %8d | %8d |" OVERLAY $(OVERLAY_OFFSET) $(OVERLAY_PARTITION_SIZE) $(OVERLAY_BIN_SIZE) $(OVERLAY_BIN_SIZE_ALIGNED) $$(($(OVERLAY_OFFSET) + $(OVERLAY_BIN_SIZE_ALIGNED))) $$(($(OVERLAY_PARTITION_SIZE) - $(OVERLAY_BIN_SIZE_ALIGNED))) ))
	$(info  )
	$(info $(shell printf "%-7s | %8s | %8s | %8s | %8s | %8s | %8s |" NAME OFFSET PT_SIZE CONTENT ALIGNED END LOSS))
	$(info $(shell printf "%-7s | %08X | %08X | %08X | %08X | %08X | %08X |" U_BOOT $(U_BOOT_OFFSET) $(U_BOOT_PARTITION_SIZE) $(U_BOOT_BIN_SIZE) $(U_BOOT_BIN_SIZE_ALIGNED) $$(($(U_BOOT_OFFSET) + $(U_BOOT_BIN_SIZE_ALIGNED))) $$(($(U_BOOT_PARTITION_SIZE) - $(U_BOOT_BIN_SIZE_ALIGNED))) ))
	$(info $(shell printf "%-7s | %08X | %08X | %08X | %08X | %08X | %08X |" ENV $(U_BOOT_ENV_OFFSET) $(U_BOOT_ENV_PARTITION_SIZE) $(U_BOOT_ENV_BIN_SIZE) $(U_BOOT_ENV_BIN_SIZE_ALIGNED) $$(($(U_BOOT_ENV_OFFSET) + $(U_BOOT_ENV_BIN_SIZE_ALIGNED))) $$(($(U_BOOT_ENV_PARTITION_SIZE) - $(U_BOOT_ENV_BIN_SIZE_ALIGNED))) ))
	$(info $(shell printf "%-7s | %08X | %08X | %08X | %08X | %08X | %08X |" KERNEL $(KERNEL_OFFSET) $(KERNEL_PARTITION_SIZE) $(KERNEL_BIN_SIZE) $(KERNEL_PARTITION_SIZE) $$(($(KERNEL_OFFSET) + $(KERNEL_PARTITION_SIZE))) $$(($(KERNEL_PARTITION_SIZE) - $(KERNEL_PARTITION_SIZE))) ))
	$(info $(shell printf "%-7s | %08X | %08X | %08X | %08X | %08X | %08X |" ROOTFS $(ROOTFS_OFFSET) $(ROOTFS_PARTITION_SIZE) $(ROOTFS_BIN_SIZE) $(ROOTFS_PARTITION_SIZE) $$(($(ROOTFS_OFFSET) + $(ROOTFS_PARTITION_SIZE))) $$(($(ROOTFS_PARTITION_SIZE) - $(ROOTFS_PARTITION_SIZE))) ))
	$(info $(shell printf "%-7s | %08X | %08X | %08X | %08X | %08X | %08X |" OVERLAY $(OVERLAY_OFFSET) $(OVERLAY_PARTITION_SIZE) $(OVERLAY_BIN_SIZE) $(OVERLAY_BIN_SIZE_ALIGNED) $$(($(OVERLAY_OFFSET) + $(OVERLAY_BIN_SIZE_ALIGNED))) $$(($(OVERLAY_PARTITION_SIZE) - $(OVERLAY_BIN_SIZE_ALIGNED))) ))
	$(info  )
	@if [ $(FIRMWARE_BIN_FULL_SIZE) -gt $(FIRMWARE_FULL_SIZE) ]; then $(FIGLET) "OVERSIZE"; fi
	sha256sum $(FIRMWARE_BIN_FULL) | awk '{print $$1 "  " filename}' filename=$$(basename $(FIRMWARE_BIN_FULL)) > $(FIRMWARE_BIN_FULL).sha256sum
	@if [ $(FIRMWARE_BIN_PART_SIZE) -gt $(FIRMWARE_PART_SIZE) ]; then $(FIGLET) "OVERSIZE"; fi
	sha256sum $(FIRMWARE_BIN_PART) | awk '{print $$1 "  " filename}' filename=$$(basename $(FIRMWARE_BIN_PART)) > $(FIRMWARE_BIN_PART).sha256sum

# rebuild a package
rebuild-%:
	$(info -------------------------------- $@)
	$(BR2_MAKE) $(subst rebuild-,,$@)-dirclean $(subst rebuild-,,$@)

# build toolchain fast
sdk:
	$(info -------------------------------- $@)
	$(BR2_MAKE) -j$(shell nproc) sdk

source:
	$(info -------------------------------- $@)
	$(BR2_MAKE) source

# build toolchain
toolchain:
	$(info -------------------------------- $@)
	$(BR2_MAKE) sdk

# flash compiled update image to the camera
update_ota: $(FIRMWARE_BIN_PART)
	$(info -------------------------------- $@)
	$(SCRIPTS_DIR)/fw_ota.sh $(FIRMWARE_BIN_PART) $(CAMERA_IP_ADDRESS)

# flash compiled full image to the camera
upgrade_ota: $(FIRMWARE_BIN_FULL)
	$(info -------------------------------- $@)
	$(SCRIPTS_DIR)/fw_ota.sh $(FIRMWARE_BIN_FULL) $(CAMERA_IP_ADDRESS)

# upload firmware to tftp server
upload_tftp: $(FIRMWARE_BIN_FULL)
	$(info -------------------------------- $@)
	busybox tftp -l $(FIRMWARE_BIN_FULL) -r $(FIRMWARE_NAME_FULL) -p $(TFTP_IP_ADDRESS)

### Buildroot

# delete all build/{package} and per-package/{package} files
br-%-dirclean:
	$(info -------------------------------- $@)
	rm -rf $(OUTPUT_DIR)/per-package/$(subst -dirclean,,$(subst br-,,$@)) \
		$(OUTPUT_DIR)/build/$(subst -dirclean,,$(subst br-,,$@))* \
		$(OUTPUT_DIR)/target
	#  \ sed -i /^$(subst -dirclean,,$(subst br-,,$@))/d $(OUTPUT_DIR)/build/packages-file-list.txt

br-%:
	$(info -------------------------------- $@)
	$(BR2_MAKE) $(subst br-,,$@)

# checkout buildroot submodule
buildroot/Makefile:
	$(info -------------------------------- $@)
	git submodule init
	git submodule update --depth 1 --recursive

# download bootloader
$(U_BOOT_BIN):
	$(WGET) -O $@ $(U_BOOT_GITHUB_URL)/u-boot-$(SOC_MODEL_LESS_Z).bin

# create config partition image
$(CONFIG_BIN):
	$(info -------------------------------- $@)
	$(OUTPUT_DIR)/host/sbin/mkfs.jffs2 \
		--little-endian \
		--squash \
		--root=$(BR2_EXTERNAL_THINGINO_PATH)/overlay/upper/ \
		--output=$(CONFIG_BIN) \
		--pad=$(CONFIG_PARTITION_SIZE)

#$(FIRMWARE_BIN_FULL): $(U_BOOT_BIN) $(CONFIG_BIN) $(KERNEL_BIN) $(ROOTFS_BIN) $(OVERLAY_BIN)
#@$(info $(shell printf "%-10s | %8d / 0x%07X | %8d / 0x%07X | %8d / 0x%07X | %8d / 0x%07X | 0x%07X | 0x%07X |" CONFIG $(CONFIG_OFFSET) $(CONFIG_OFFSET) $(CONFIG_PARTITION_SIZE) $(CONFIG_PARTITION_SIZE) $(CONFIG_BIN_SIZE) $(CONFIG_BIN_SIZE) $(CONFIG_BIN_SIZE_ALIGNED) $(CONFIG_BIN_SIZE_ALIGNED) $$(($(CONFIG_OFFSET) + $(CONFIG_BIN_SIZE_ALIGNED))) $$(($(CONFIG_PARTITION_SIZE) - $(CONFIG_BIN_SIZE_ALIGNED))) ))
#@dd if=$(CONFIG_BIN) bs=$(CONFIG_BIN_SIZE) seek=$(CONFIG_OFFSET)B count=1 of=$@ conv=notrunc status=none
$(FIRMWARE_BIN_FULL): $(U_BOOT_BIN) $(KERNEL_BIN) $(ROOTFS_BIN) $(OVERLAY_BIN)
	$(info -------------------------------- $@)
	dd if=/dev/zero bs=$(SIZE_8M) skip=0 count=1 status=none | tr '\000' '\377' > $@
	dd if=$(U_BOOT_BIN) bs=$(U_BOOT_BIN_SIZE) seek=$(U_BOOT_OFFSET)B count=1 of=$@ conv=notrunc status=none
	dd if=$(KERNEL_BIN) bs=$(KERNEL_BIN_SIZE) seek=$(KERNEL_OFFSET)B count=1 of=$@ conv=notrunc status=none
	dd if=$(ROOTFS_BIN) bs=$(ROOTFS_BIN_SIZE) seek=$(ROOTFS_OFFSET)B count=1 of=$@ conv=notrunc status=none
	dd if=$(OVERLAY_BIN) bs=$(OVERLAY_BIN_SIZE) seek=$(OVERLAY_OFFSET)B count=1 of=$@ conv=notrunc status=none

$(FIRMWARE_BIN_PART): $(KERNEL_BIN) $(ROOTFS_BIN) $(OVERLAY_BIN)
	$(info -------------------------------- $@)
	dd if=/dev/zero bs=$(FIRMWARE_PART_SIZE) skip=0 count=1 status=none | tr '\000' '\377' > $@
	dd if=$(KERNEL_BIN) bs=$(KERNEL_BIN_SIZE) seek=0 count=1 of=$@ conv=notrunc status=none
	dd if=$(ROOTFS_BIN) bs=$(ROOTFS_BIN_SIZE) seek=$(KERNEL_PARTITION_SIZE)B count=1 of=$@ conv=notrunc status=none
	dd if=$(OVERLAY_BIN) bs=$(OVERLAY_BIN_SIZE) seek=$(OVERLAY_OFFSET_PART)B count=1 of=$@ conv=notrunc status=none

# rebuild kernel
$(KERNEL_BIN):
	$(info -------------------------------- $@)
	$(BR2_MAKE) linux-rebuild
#	mv -vf $(OUTPUT_DIR)/images/uImage $@

# rebuild rootfs
$(ROOTFS_BIN):
	$(info -------------------------------- $@)
	$(BR2_MAKE) all

# create .tar file of rootfs
$(ROOTFS_TAR):
	$(info -------------------------------- $@)
	$(BR2_MAKE) all

$(OVERLAY_BIN): $(U_BOOT_BIN)
	$(info -------------------------------- $@)
	if [ $(OVERLAY_PARTITION_SIZE) -lt $(OVERLAY_LLIMIT) ]; then $(FIGLET) "OVERLAY IS TOO SMALL"; fi
	if [ -f $(OVERLAY_BIN) ]; then rm $(OVERLAY_BIN); fi
	$(OUTPUT_DIR)/host/sbin/mkfs.jffs2 --little-endian --squash \
		--root=$(BR2_EXTERNAL_THINGINO_PATH)/overlay/upper/ --output=$(OVERLAY_BIN) \
		--pad=$(OVERLAY_PARTITION_SIZE) --eraseblock=$(ALIGN_BLOCK)
       #	--pagesize=$(ALIGN_BLOCK)
help:
	$(info -------------------------------- $@)
	@echo "\n\
	Usage:\n\
	  make bootstrap      install system deps\n\
	  make update         update local repo from GitHub\n\
	  make                build and pack everything\n\
	  make build          build kernel and rootfs\n\
	  make cleanbuild     build everything from scratch\n\
	  make pack_full      create a full firmware image\n\
	  make pack_update    create an update firmware image (no bootloader)\n\
	  make clean          clean before reassembly\n\
	  make rebuild-<pkg>  perform a clean package rebuild for <pkg>\n\
	  make help           print this help\n\
	  \n\
	  make upgrade_ota IP=192.168.1.10\n\
	                      upload the full firmware file to the camera\n\
	                        over network, and flash it\n\n\
	  make update_ota IP=192.168.1.10\n\
	                      upload the update firmware file to the camera\n\
	                        over network, and flash it\n\n\
	"
