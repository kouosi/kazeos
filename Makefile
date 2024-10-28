ARCH ?= x86_64
IMAGE_NAME := kazeos

define print
	@echo "\033[0;34m**$1 **\033[0m"
endef

.PHONY: all
all: $(IMAGE_NAME).iso

.PHONY: run
run: run-$(ARCH)

.PHONY: run-bios
run-bios: $(IMAGE_NAME).iso
	@$(call print, "Running: x86_64 BIOS")
	@mkdir -p log/$(shell date +%Y_%m_%d)
	@qemu-system-x86_64 -M q35 -m 2G -cdrom $(IMAGE_NAME).iso -boot d \
		-serial file:log/$$(date "+%Y_%m_%d/%H_%M_%S").log

.PHONY: run-x86_64
run-x86_64: ovmf $(IMAGE_NAME).iso
	@$(call print, "Running: x86_64 UEFI")
	@mkdir -p log/$(shell date +%Y_%m_%d)
	@qemu-system-x86_64 -M q35 -m 2G -cdrom $(IMAGE_NAME).iso -boot d \
		-bios ovmf/x86_64/OVMF.fd \
		-serial file:log/$$(date "+%Y_%m_%d/%H_%M_%S").log

ovmf:
	@$(call print, "Downloading: OVMF")
	@mkdir -p ovmf/x86_64
	@cd ovmf/x86_64 && curl -o OVMF.fd https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd

limine/limine:
	@$(call print, "Downloading: Limine")
	@rm -rf limine
	@git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1
	@$(call print, "Building: Limine")
	@$(MAKE) -C limine

.PHONY: kernel
kernel:
	@$(call print, "Building: $(ARCH) kernel")
	@cd kernel && zig build -Darch=$(ARCH)

$(IMAGE_NAME).iso: limine/limine kernel
	@$(call print, "Building: ISO image")
	@rm -rf iso_root/
	@mkdir -p iso_root/boot/
	@cp kernel/zig-out/bin/kurisu.kernel iso_root/boot/
	@mkdir -p iso_root/boot/limine/
	@cp config/limine.conf iso_root/boot/limine/
	@mkdir -p iso_root/EFI/BOOT/
	@cp limine/BOOTX64.EFI iso_root/EFI/BOOT/
	@cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin -t iso_root/boot/limine/
	@cp limine/limine-uefi-cd.bin iso_root/boot/limine/
	@xorriso -report_about WARNING -as mkisofs \
		-b boot/limine/limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot boot/limine/limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		iso_root -o $(IMAGE_NAME).iso
	@./limine/limine bios-install $(IMAGE_NAME).iso 2> /dev/null
	@rm -rf iso_root/

.PHONY: clean
clean:
	@$(call print, "Cleaning: Cache")
	@rm -rf iso_root/ $(IMAGE_NAME).iso
	@cd kernel && rm -rf .zig-cache/ zig-out/

.PHONY: clean-all
clean-all: clean
	@$(call print, "Cleaning: All")
	@rm -rf limine/ ovmf/ log/
