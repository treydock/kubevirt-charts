# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"
SED := $(shell command -v gsed 2>/dev/null || echo sed)

KUBEVIRT_VERSION := v1.9.0
CDI_VERSION := v1.66.1

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
		charts/cdi-crd/templates/clusterrole.yaml

update-kubevirt-roles: download-kubevirt-manifest yamlfmt
	@cat kubevirt-operator.yaml | yq 'select(.kind == "ClusterRole" and .metadata.name == "kubevirt.io:operator")' > \
		charts/kubevirt/templates/clusterrole.yaml
	@echo "---" >> charts/kubevirt/templates/clusterrole.yaml
	@cat kubevirt-operator.yaml | yq 'select(.kind == "ClusterRole" and .metadata.name == "kubevirt-operator")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 >> \
		charts/kubevirt/templates/clusterrole.yaml
	@$(SED) -i 's/name: kubevirt-operator/name: {{ include "kubevirt.operator.name" . }}/g' \
		charts/kubevirt/templates/clusterrole.yaml
	@$(SED) -i -r 's/labels:/labels:\n    {{- include "kubevirt.labels" . | nindent 4 }}/g' \
		charts/kubevirt/templates/clusterrole.yaml
	@cat kubevirt-operator.yaml | yq 'select(.kind == "Role")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 > \
		charts/kubevirt/templates/role.yaml
	@$(SED) -i 's/name: kubevirt-operator/name: {{ include "kubevirt.operator.name" . }}/g' \
		charts/kubevirt/templates/role.yaml
	@$(SED) -i 's/namespace: kubevirt/namespace: {{ .Release.Namespace }}/g' \
		charts/kubevirt/templates/role.yaml
	@$(SED) -i -r 's/labels:/labels:\n    {{- include "kubevirt.labels" . | nindent 4 }}/g' \
		charts/kubevirt/templates/role.yaml

update-cdi-roles: download-cdi-manifest yamlfmt
	@cat cdi-operator.yaml | yq 'select(.kind == "ClusterRole")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 > \
		charts/cdi/templates/clusterrole.yaml
	@$(SED) -i 's/name: cdi-operator-cluster/name: {{ printf "%s-cluster" (include "cdi.operator.name" .) }}/g' \
		charts/cdi/templates/clusterrole.yaml
	@$(SED) -i -r 's/labels:/labels:\n    {{- include "cdi.labels" . | nindent 4 }}/g' \
		charts/cdi/templates/clusterrole.yaml
	@cat cdi-operator.yaml | yq 'select(.kind == "Role")' \
		| $(YAMLFMT) -in -formatter indentless_arrays=true,max_line_length=80 \
		| grep -v "app.kubernetes.io/managed-by" > \
		charts/cdi/templates/role.yaml
	@$(SED) -i 's/name: cdi-operator/name: {{ include "cdi.operator.name" . }}/g' \
		charts/cdi/templates/role.yaml
	@$(SED) -i 's/namespace: cdi/namespace: {{ .Release.Namespace }}/g' \
		charts/cdi/templates/role.yaml
	@$(SED) -i -r 's/labels:/labels:\n    {{- include "cdi.labels" . | nindent 4 }}/g' \
		charts/cdi/templates/role.yaml

verify-helm-kubevirt-crds: download-kubevirt-manifest
	@diff -uw \
		<( helm template charts/kubevirt-crd | yq 'select(.kind == "CustomResourceDefinition")' | grep -v -E "^(#|---)" ) \
		<( cat kubevirt-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' )

verify-helm-cdi-crds: download-cdi-manifest
	@diff -uw \
		<( helm template charts/cdi-crd | yq 'select(.kind == "CustomResourceDefinition")' | grep -v -E "^(#|---)" ) \
		<( cat cdi-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' )

verify-helm-cdi-roles: download-cdi-manifest
	@helm dependency update charts/cdi
	@echo 'Verify ClusterRole resources'
	@diff -uw \
		<( helm template charts/cdi --no-hooks | yq 'select(.kind == "ClusterRole")' | grep -v -E "^#" | grep -v -E "(kubernetes.io|helm.sh)" ) \
		<( cat cdi-operator.yaml | yq 'select(.kind == "ClusterRole")' )
	@echo 'Verify Role resources'
	@diff -uw \
		<( helm template charts/cdi -n cdi --no-hooks | yq 'select(.kind == "Role")' | grep -v -E "^#" | grep -v -E "kubernetes.io/(managed-by|name|instance|version)" | grep -v -E "(helm.sh)" ) \
		<( cat cdi-operator.yaml | yq 'select(.kind == "Role")' | grep -v -E "(kubernetes.io/managed-by)" )

verify-helm-kubevirt-roles: download-kubevirt-manifest
	@helm dependency update charts/kubevirt
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
	update-kubevirt-roles \
	update-cdi-roles \
	verify-helm-crds \
	verify-helm-cdi-roles \
	verify-helm-kubevirt-roles \
	$(NULL)
