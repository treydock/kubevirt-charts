# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

KUBEVIRT_VERSION := v1.8.2

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

update-helm-crds: download-kubevirt-manifest
	@cat kubevirt-operator.yaml | yq 'select(.kind == "CustomResourceDefinition")' \
		| yamlfmt -in -formatter indentless_arrays=true,max_line_length=80 > \
		charts/kubevirt-crd/templates/crd.yaml

verify-helm-crds: download-kubevirt-manifest
	@diff -uw \
		<( helm template charts/kubevirt-crd | yq 'select(.kind == "CustomResourceDefinition")' | grep -v -E "^#" ) \
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
	helm-docs \
	verify-helm-docs \
	download-kubevirt-manifest \
	update-helm-crds \
	verify-helm-crds \
	verify-helm-roles \
	$(NULL)
