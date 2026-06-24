# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"

KUBEVIRT_VERSION := v1.8.2
CDI_VERSION := v1.65.0

YAMLFMT = $(LOCALBIN)/yamlfmt
YAMLFMT_VERSION ?= v0.21.0

yamlfmt: $(YAMLFMT)
$(YAMLFMT): $(LOCALBIN)
	$(call go-install-tool,$(YAMLFMT),github.com/google/yamlfmt/cmd/yamlfmt,$(YAMLFMT_VERSION))

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f "$(1)-$(3)" ] && [ "$$(readlink -- "$(1)" 2>/dev/null)" = "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f "$(1)" ;\
GOBIN="$(LOCALBIN)" go install $${package} ;\
mv "$(LOCALBIN)/$$(basename "$(1)")" "$(1)-$(3)" ;\
} ;\
ln -sf "$$(realpath "$(1)-$(3)")" "$(1)"
endef

helm-docs:
	@docker run --rm -v ${PWD}/charts:/helm-docs -w /helm-docs jnorwood/helm-docs:v1.14.2 -s file

verify-helm-docs: helm-docs
	@echo Checking helm charts are up to date... >&2
	@git --no-pager diff charts
	@echo 'If this test fails, it is because the git diff is non-empty after running "make helm-docs".' >&2
	@echo 'To correct this, locally run "make helm-docs", commit the changes, and re-run tests.' >&2
	@git diff --quiet --exit-code charts

download-kubevirt-manifest:
	@curl -s -L -O https://github.com/kubevirt/kubevirt/releases/download/$(KUBEVIRT_VERSION)/kubevirt-operator.yaml

download-cdi-manifest:
	@curl -s -L -O https://github.com/kubevirt/containerized-data-importer/releases/download/$(CDI_VERSION)/cdi-operator.yaml

update-kubevirt-crds: download-kubevirt-manifest yamlfmt
	@cat kubevirt-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 > \
		charts/kubevirt-crd/templates/crd.yaml

update-cdi-crds: download-cdi-manifest yamlfmt
	@cat cdi-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 > \
		charts/cdi-crd/templates/crd.yaml

verify-helm-crds: download-kubevirt-manifest
	@diff -uw \
		<( helm template charts/kubevirt-crd | yq 'select(.kind == "CustomResourceDefinition")' | grep -v -E "^(#|---)" ) \
		<( cat kubevirt-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' )

verify-helm-roles: download-kubevirt-manifest
	@echo 'Verify ClusterRole resources'
	@diff -uw \
		<( helm template charts/kubevirt --no-hooks | yq 'select(.kind == "ClusterRole")' | grep -v -E "^#" | grep -v -E "(kubernetes.io|helm.sh)" ) \
		<( cat kubevirt-operator.yaml | yq 'select(.kind == "ClusterRole")' )
	@echo 'Verify Role resources'
	@diff -uw \
		<( helm template charts/kubevirt -n kubevirt --no-hooks | yq 'select(.kind == "Role")' | grep -v -E "^#" | grep -v -E "(kubernetes.io|helm.sh)" ) \
		<( cat kubevirt-operator.yaml | yq 'select(.kind == "Role")' )

.PHONY: \
	yamlfmt \
	helm-docs \
	verify-helm-docs \
	download-kubevirt-manifest \
	update-kubevirt-crds \
	update-cdi-crds \
	verify-helm-crds \
	verify-helm-roles \
	$(NULL)
