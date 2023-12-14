BUILDDIR=builddir
REPOS := $(HOME)/git/xnvme
NAME := xnvme
VERSION := 0.7.3
TGZ_FILENAME := $(NAME)-$(VERSION).tar.gz
TGZ_FILEPATH := input/$(TGZ_FILENAME)
ORIG_FILEPATH := $(BUILDDIR)/$(NAME)_$(VERSION).orig.tar.gz
SRC_ROOT := $(BUILDDIR)/src

.PHONY:
default: info clean prep generate create_orig extract inject build lint

.PHONY: info
info:
	@echo "# Info ..."
	@echo "# SRC_ROOT: ${SRC_ROOT}"
	@echo "# NAME: ${NAME}"
	@echo "# VERSION: ${VERSION}"
	@echo "# TGZ_FILEPATH: ${TGZ_FILEPATH}"
	@echo "# TGZ_FILENAME: ${TGZ_FILENAME}"
	@echo "# ORIG_FILEPATH: ${ORIG_FILEPATH}"
	@echo "# Info: done!"

.PHONY: clean
clean:
	@echo "# Cleaning: ..."
	rm -r builddir || true
	@echo "# Cleaning: done!"

.PHONY: clean-input
clean-input:
	@echo "# Cleaning: ..."
	rm input/* || true
	@echo "# Cleaning: done!"

.PHONY: prep
prep:
	@echo "# Prepping: ..."
	mkdir -p $(BUILDDIR)
	@echo "# Prepping: done!"

$(TGZ_FILEPATH):
	@echo "# Generating source-archive ..."
	cd $(REPOS) && make clean gen-src-archive ALLOW_DIRTY=1
	cp $(REPOS)/builddir/meson-dist/* input/.

.PHONY: generate
generate: $(TGZ_FILEPATH)
	@echo "# generating source-archive: done!"

.PHONY: create_orig
create_orig:
	@echo "# creating .orig.tar.gz: ..."
	cp $(TGZ_FILEPATH) $(ORIG_FILEPATH)
	@echo "# creating .orig.tar.gz: done!"

.PHONY: extract
extract:
	@echo "# Extracting source-archive ..."
	mkdir -p $(SRC_ROOT)
	tar -xzf $(TGZ_FILEPATH) --strip-components=1 -C $(SRC_ROOT)
	@echo "# Extracting source-archive: done!"

.PHONY: inject
inject:
	@echo "# Inject pkg-files: ..."
	cp -r debian $(SRC_ROOT)
	@echo "# Inject pkg-files: done!"

.PHONY: build
build:
	@echo "# Build: ..."
	cd $(SRC_ROOT); dpkg-buildpackage -us -uc
	@echo "# Build: done!"

# Produce the package .symbols
# note: the package needs to be re-built in case of symbolchanges
.PHONY: symbols
symbols:
	@echo "# symbols: ..."
	dpkg-gensymbols -plibxnvme0 -Pbuilddir/src/debian/libxnvme0 -Odebian/libxnvme0.symbols
	python3 symbols.py debian/libxnvme0.symbols
	@echo "# symbols: done!"

# After building we can check it
.PHONY: lint
lint:
	lintian -iIE --tag-display-limit 0 $(BUILDDIR)/*.deb
	lintian -iIE --tag-display-limit 0 $(BUILDDIR)/*.dsc

# Once verified, we can sign it
.PHONY: sign
sign:
	@echo "# Sign the package: ..."
	debsign $(BUILDDIR)/*.changes
	@echo "# Sign the package: done!"

# Once signed we can upload it to mentors for review
.PHONY: upload
upload:
	@echo "# Upload the package (to mentors): ..."
	[ -f ~/.dput.cf ] || cp dput.cf ~/.dput.cf
	dput mentors $(BUILDDIR)/xnvme*.changes
	@echo "# Upload the package (to mentors): done!"

#
# Environment to build the package in
#
.PHONY: docker
docker:
	@docker run -it -w /tmp/xnvme/pkgs/deb --mount type=bind,source="$(shell cd $(REPOS) && pwd)",target=/tmp/xnvme --mount type=bind,source="$(shell pwd)",target=/tmp/pkg -w /tmp/pkg ghcr.io/xnvme/xnvme-deps-debian-packaging:main bash
