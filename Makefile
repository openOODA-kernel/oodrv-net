OODA_COMPILER ?= /Projects/openOODA-core/oodac/bin/oodac
export OODA_COMPILER
OODA_OODAR_ROOT ?= /Projects/openOODA-core/oodar/core
export OODA_OODAR_ROOT
OODA_READDIR ?= /Projects:/proc:/sys
OODA_WRITEDIR ?= $(CURDIR):/tmp
OO_LIST_AMBIENT_QUOTA ?= 8589934592
export OO_LIST_AMBIENT_QUOTA
OODA_FS_READDIR ?= $(OODA_READDIR)
export OODA_FS_READDIR
OODA_FS_WRITEDIR ?= $(OODA_WRITEDIR)
export OODA_FS_WRITEDIR
OODA_NO_JAIL ?= 1
export OODA_NO_JAIL
BIN := bin/oodrv-net
TESTBIN := bin/test_oodrv-net
TESTBIN2 := bin/test_oodrv-net-refusal
REPO_NAME := oodrv-net
VER := 0.6.1
SRC := cli/main.oo anchor.oo cli/dispatch.oo cli/about.oo cli/identity.oo core/anchor.oo core/engine.oo core/netdrv_run.oo core/net/driver_net_dma_ring.oo core/net/pktio_ring.oo core/net/rdma_qp_guard.oo core/net/tsn_canfd.oo core/net/netdrv_wired_verdicts.oo core/radio/driver_wifi80211.oo core/radio/driver_bt_hci.oo core/radio/driver_wwan.oo core/radio/netdrv_radio_verdicts.oo core/fs/fsprobe.oo core/fs/gate.oo core/fs/manifest.oo core/fs/state.oo tests/test_functional.oo tests/test_refusal.oo
ENV := OODA_COMPILER=$(OODA_COMPILER) OODA_OODAR_ROOT=$(OODA_OODAR_ROOT) OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODA_FS_READDIR=$(OODA_FS_READDIR) OODA_FS_WRITEDIR=$(OODA_FS_WRITEDIR) OODA_NO_JAIL=$(OODA_NO_JAIL)
OO_ALL := $(shell find . -name '*.oo' -not -path './.git/*' -not -path './bin/*' -not -path './.ooda-cache/*' -not -path './dist/*' -not -path './.blackbox/*' | sort)

.PHONY: all build verify test parity det check line-cap file-law academy density vocab shape link-law clean

all: build verify test det

build: $(BIN)

$(BIN): $(SRC) $(OO_ALL)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build cli/main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -f $(BIN) bin/oodrv-rdma
	@cp -f $(BIN) bin/oodrv-wireless
	@cp -f $(BIN) bin/oodrv-bus
	@echo "built $(BIN)"

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/.git/" | grep -v "/bin/" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./bin*" -not -path "./dist*" -not -path "./.ooda-cache*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

vocab:
	@if grep -riE "sovereign|Pillar [0-9]|moonshot|dogfight|bootstrap|Stage [0-9]" --include="*.oo" --include="*.oot" . ; then \
		echo "FAIL: banned vocabulary found"; exit 1; \
	fi; \
	echo "PASS: vocabulary check holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*"); do \
		$(ENV) $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density vocab check shape link-law

parity: $(BIN)
	@$(ENV) ./$(BIN) oodrv-net status | grep -q "oodrv-net 0.6.1: PASS"
	@$(ENV) ./$(BIN) oodrv-rdma status | grep -q "oodrv-rdma 0.6.1: PASS"
	@$(ENV) ./$(BIN) oodrv-wireless status | grep -q "oodrv-wireless 0.6.1: PASS"
	@$(ENV) ./$(BIN) oodrv-bus status | grep -q "oodrv-bus 0.6.1: PASS"
	@$(ENV) ./bin/oodrv-rdma status | grep -q "oodrv-rdma 0.6.1: PASS"
	@$(ENV) ./$(BIN) --persona x status >/dev/null 2>&1; [ $$? -eq 2 ] || (echo "FAIL: --persona not refused with exit 2"; exit 1)
	@$(ENV) ./$(BIN) --list-personas >/dev/null 2>&1; [ $$? -eq 2 ] || (echo "FAIL: --list-personas not refused with exit 2"; exit 1)
	@$(ENV) ./$(BIN) --unknown-flag-zzz >/dev/null 2>&1; [ $$? -eq 2 ] || (echo "FAIL: unknown flag not refused with exit 2"; exit 1)
	@echo "PASS: persona subcommand parity + flag refusal gate (4 personas)"

test: $(BIN) parity
	@$(ENV) $(OODA_COMPILER) build tests/test_functional.oo -o $(TESTBIN) > /dev/null
	@$(ENV) ./$(TESTBIN) | grep -q "PASS: 16/16 assertions" && echo "PASS: axis-1 functional suite (16 assertions)"
	@$(ENV) $(OODA_COMPILER) build tests/test_refusal.oo -o $(TESTBIN2) > /dev/null
	@$(ENV) ./$(TESTBIN2) | grep -q "PASS: 30/30 assertions" && echo "PASS: axis-2 refusal suite (30 assertions)"
	@if ./$(BIN) --zzz-9 > /dev/null 2>&1; then echo "FAIL: unknown flag accepted"; exit 1; else echo "PASS: unknown flag fails closed (non-zero exit)"; fi
	@$(ENV) ./$(BIN) --help | grep -q "$(REPO_NAME) $(VER)" && echo "PASS: --help"
	@$(ENV) ./$(BIN) --version | grep -q "$(VER)" && echo "PASS: --version"
	@$(ENV) ./$(BIN) status | grep -q "PASS" && echo "PASS: status"
	@$(ENV) ./$(BIN) verify | grep -q "verify OK" && echo "PASS: verify"
	@$(ENV) ./$(BIN) inspect | grep -q '"status":"pass"' && echo "PASS: inspect"
	@$(ENV) ./$(BIN) --self-test | grep -q "PASS" && echo "PASS: --self-test"
	@$(ENV) ./$(BIN) --json | grep -q '"status":"pass"' && echo "PASS: --json"
	@$(ENV) ./$(BIN) --json > .ooda-cache/r1.txt && $(ENV) ./$(BIN) --json > .ooda-cache/r2.txt && cmp -s .ooda-cache/r1.txt .ooda-cache/r2.txt && echo "PASS: double-run output determinism"
	@$(ENV) ./$(BIN) inspect /proc/version | grep -q '"kind":"file"' && echo "PASS: inspect reads a real file under FsReadCap"
	@$(ENV) ./$(BIN) inspect /proc/self | grep -q '"kind":"dir"' && echo "PASS: inspect enumerates a real directory"
	@$(ENV) ./$(BIN) inspect /nonexistent-ooda-probe | grep -q '"kind":"missing"' && echo "PASS: inspect classifies an absent path"
	@$(ENV) ./$(BIN) load /proc/version | grep -q "kind=file" && echo "PASS: load prints real file content"
	@mkdir -p .ooda-cache && printf '1 0 12 3 0\n2 1 40 25 0\n3 4 7 9 2\n' > .ooda-cache/manifest.txt && printf '1 0 12 3 0\nbad line here\n' > .ooda-cache/bad_manifest.txt
	@$(ENV) ./$(BIN) --manifest .ooda-cache/manifest.txt | grep -q "records=3 ok" && echo "PASS: loads a real manifest under FsReadCap"
	@if $(ENV) ./$(BIN) --manifest .ooda-cache/bad_manifest.txt | grep -q "code=22"; then echo "PASS: rejects a malformed manifest record"; else exit 1; fi
	@$(ENV) ./$(BIN) --tui | grep -q "theme=ooda-dark" && echo "PASS: --tui renders the default theme frame"
	@$(ENV) ./$(BIN) theme 1982 | grep -q "theme=1982" && echo "PASS: theme <name> resolves the unified palette"
	@$(ENV) ./$(BIN) theme high-contrast --json | grep -q '"theme":"high-contrast"' && echo "PASS: theme --json emits the palette descriptor"
	@if ./$(BIN) theme bogus-theme > /dev/null 2>&1; then echo "FAIL: unknown theme accepted"; exit 1; else echo "PASS: unknown theme fails closed"; fi
	@out="$$($(ENV) ./$(BIN) about)"; \
	missing=""; \
	for k in Binary Organization Summary Subcommands Capabilities Theme; do \
		echo "$$out" | grep -q "^$$k: " || missing="$$missing $$k"; \
	done; \
	if [ -n "$$missing" ]; then echo "FAIL: about is missing$$missing"; exit 1; fi; \
	echo "PASS: about descriptor (Binary, Organization, Summary, Subcommands, Capabilities, Theme)"
	@$(ENV) ./$(BIN) about --json | grep -q '"theme":"ooda-dark"' && echo "PASS: about --json emits the theme field"
	@if $(ENV) ./$(BIN) about status > /dev/null 2>&1; then echo "FAIL: about accepted a second verb"; exit 1; else echo "PASS: about refuses a second verb fail closed"; fi
	@$(ENV) ./$(BIN) nic | grep -q "^nic: PASS" && echo "PASS: nic wired driver"
	@$(ENV) ./$(BIN) pktio | grep -q "^pktio: PASS" && echo "PASS: pktio wired driver"
	@$(ENV) ./$(BIN) rdma | grep -q "^rdma: PASS" && echo "PASS: rdma wired driver"
	@$(ENV) ./$(BIN) tsn-canfd | grep -q "^tsn-canfd: PASS" && echo "PASS: tsn-canfd wired driver"
	@$(ENV) ./$(BIN) wifi80211 | grep -q "^wifi80211: PASS" && echo "PASS: wifi80211 radio driver"
	@$(ENV) ./$(BIN) bt-hci | grep -q "^bt-hci: PASS" && echo "PASS: bt-hci radio driver"
	@$(ENV) ./$(BIN) wwan | grep -q "^wwan: PASS" && echo "PASS: wwan radio driver"
	@if $(ENV) ./$(BIN) nic bogus > /dev/null 2>&1; then echo "FAIL: a network driver accepted a second argument"; exit 1; else echo "PASS: a network driver refuses a second argument fail closed"; fi
	@echo "=== testing the CWE-22 path admission gate ==="
	@$(ENV) ./$(BIN) --save ../cwe22_escape.oot > /dev/null 2>&1; rc=$$?; [ $$rc -eq 2 ] || { echo "FAIL: traversal rc=$$rc (want 2)"; exit 1; }
	@test ! -f ../cwe22_escape.oot && echo "PASS: CWE-22 traversal refused with exit 2 and no file written"
	@echo "ALL TESTS PASSED"

det: $(BIN)
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_a > /dev/null
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_b > /dev/null
	@cmp -s .ooda-cache/det_a .ooda-cache/det_b && sha256sum .ooda-cache/det_a && echo "PASS: deterministic build (byte-identical)" || (echo "FAIL: nondeterministic build"; exit 1)

clean:
	@rm -rf bin dist .ooda-cache

shape:
	@violations=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./bin/*"); do \
		awk '/^[[:space:]]*(pub[[:space:]]+)?fn[[:space:]]/ { if (started) { len = NR - start; if (len > 64) print "FNLEN|" FILENAME "|" fn "|" len } started = 1; start = NR; if ($$1 == "pub") fn = $$3; else fn = $$2; gsub(/\(.*/, "", fn) } END { if (started) { len = NR - start + 1; if (len > 64) print "FNLEN|" FILENAME "|" fn "|" len } }' "$$f" > .ooda-cache-shape.tmp; \
		n=$$(grep -cE "^[[:space:]]*(pub[[:space:]]+)?fn " "$$f" || true); \
		if [ "$$n" -gt 8 ]; then echo "SHAPE|$$f|-|$$n" >> .ooda-cache-shape.tmp; fi; \
		while IFS='|' read -r kind path name value; do \
			[ -z "$$kind" ] && continue; \
			echo "VIOLATION: shape law $$kind|$$path|$$name|$$value"; violations=$$((violations+1)); \
		done < .ooda-cache-shape.tmp; \
	done; rm -f .ooda-cache-shape.tmp; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations shape violations"; exit 1; fi; \
	echo "PASS: shape law holds (<=8 fns/page, <=64 lines/fn)"

link-law:
	@violations=0; \
	for f in $$(find . -type l -not -path "./.git/*" 2>/dev/null); do \
		echo "VIOLATION: symbolic link $$f"; violations=$$((violations+1)); \
	done; \
	for f in $$(find . -type f -links +1 -not -path "./.git/*" 2>/dev/null); do \
		echo "VIOLATION: hard link $$f"; violations=$$((violations+1)); \
	done; \
	if grep -qE '(^|[^a-zA-Z_-])ln[ ]-s' Makefile; then \
		echo "VIOLATION: the Makefile creates a symbolic link"; violations=$$((violations+1)); \
	fi; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations link-law violations"; exit 1; fi; \
	echo "PASS: link law holds (Rule 1.25 zero symlinks/hardlinks)"
