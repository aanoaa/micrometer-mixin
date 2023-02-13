GOPATH := $(shell go env GOPATH)
JB_BIN=$(GOPATH)/bin/jb
JSONNET_BIN=$(GOPATH)/bin/jsonnet
JSONNETLINT_BIN=$(GOPATH)/bin/jsonnet-lint
JSONNETFMT_BIN=$(GOPATH)/bin/jsonnetfmt
JSONNET_VENDOR=vendor
OUT=out

MIXIN_LIB=mixin.libsonnet config.libsonnet

.PHONY: all
all: fmt build lint

$(OUT):
	mkdir -p $@

.PHONY: build
build: rules alerts dashboards

.PHONY: rules
rules: $(JSONNET_BIN) $(JSONNET_VENDOR) $(MIXIN_LIB) $(OUT)/rules.yaml

$(OUT)/rules.yaml: lib/rules.jsonnet rules/rules.libsonnet $(OUT)
	$(JSONNET_BIN) -J $(JSONNET_VENDOR) -S lib/rules.jsonnet > $@

.PHONY: alerts
alerts: $(JSONNET_BIN) $(JSONNET_VENDOR) $(MIXIN_LIB) $(OUT)/alerts.yaml

$(OUT)/alerts.yaml: lib/alerts.jsonnet alerts/alerts.libsonnet $(OUT)
	$(JSONNET_BIN) -J $(JSONNET_VENDOR) -S lib/alerts.jsonnet > $@

.PHONY: dashboards
dashboards: $(OUT)/micrometer.json

$(OUT)/micrometer.json: $(JSONNET_BIN) $(JSONNET_VENDOR) $(MIXIN_LIB) lib/dashboards.jsonnet $(OUT)
	$(JSONNET_BIN) -J $(JSONNET_VENDOR) -m $(OUT) lib/dashboards.jsonnet

.PHONY: lint
lint: rules-lint

.PHONY: rules-lint
rules-lint: $(JSONNETLINT_BIN)
	@find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNETLINT_BIN) -J vendor

.PHONY: fmt
fmt: $(JSONNETFMT_BIN)
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNETFMT_BIN) $(JSONNETFMT_ARGS) -i

.PHONY: clean
clean:
	rm -rf $(OUT)

$(JSONNET_BIN):
	go install github.com/google/go-jsonnet/cmd/jsonnet@latest

$(JSONNETLINT_BIN):
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@latest

$(JSONNETFMT_BIN):
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest

$(JSONNET_VENDOR): $(JB_BIN) jsonnetfile.json
	$(JB_BIN) install
