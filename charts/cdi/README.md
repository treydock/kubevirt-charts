# cdi

![Version: v1.65.0](https://img.shields.io/badge/Version-v1.65.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.65.0](https://img.shields.io/badge/AppVersion-v1.65.0-informational?style=flat-square)

A Helm chart for the CDI

## Installing

Before you can install, you need to add the `kubevirt` repo to [Helm](https://helm.sh)

```shell
helm repo add kubevirt https://kubevirt.github.io/kubevirt
helm repo update
```

**This chart must be installed after installing the [cdi-crd chart](../cdi-crd)**

Now you can install the chart:

```shell
helm upgrade cdi kubevirt/cdi --install -n cdi
```

## Values

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.imageRegistry | string | `""` | The image registry to use for all images |

### Operator

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| operator.replicas | int | `1` | Operator replicas |
| operator.image.registry | string | `"quay.io"` | Operator image registry |
| operator.image.repository | string | `"kubevirt/cdi-operator"` | Operator image repository |
| operator.image.tag | string | Chart's appVersion | Operator image tag |
| operator.image.pullPolicy | string | `"IfNotPresent"` | Operator image pull policy |
| operator.imagePullSecrets | list | `[]` | image pull secret configs for existing image pull secrets |
| operator.resources | object | `{"requests":{"cpu":"100m","memory":"150Mi"}}` | Operator container resources |
| operator.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Operator container security context |
| operator.verbosity | int | `1` | Verbosity level for CDI operator |
| operator.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | The Operator node selector |
| operator.podSecurityContext | object | `{"runAsNonRoot":true}` | Operator pod security context |

### Images

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| images.controller.registry | string | `"quay.io"` | Controller image registry |
| images.controller.repository | string | `"kubevirt/cdi-controller"` | Controller image repository |
| images.controller.tag | string | Chart's app version | Controller image tag |
| images.importer.registry | string | `"quay.io"` | Importer image registry |
| images.importer.repository | string | `"kubevirt/cdi-importer"` | Importer image repository |
| images.importer.tag | string | Chart's app version | Importer image tag |
| images.cloner.registry | string | `"quay.io"` | Cloner image registry |
| images.cloner.repository | string | `"kubevirt/cdi-cloner"` | Cloner image repository |
| images.cloner.tag | string | Chart's app version | Cloner image tag |
| images.apiserver.registry | string | `"quay.io"` | API Server image registry |
| images.apiserver.repository | string | `"kubevirt/cdi-apiserver"` | API Server image repository |
| images.apiserver.tag | string | Chart's app version | API Server image tag |
| images.uploadServer.registry | string | `"quay.io"` | Upload server image registry |
| images.uploadServer.repository | string | `"kubevirt/cdi-uploadserver"` | Upload server image repository |
| images.uploadServer.tag | string | Chart's app version | Upload server image tag |
| images.uploadProxy.registry | string | `"quay.io"` | Upload proxy image registry |
| images.uploadProxy.repository | string | `"kubevirt/cdi-uploadproxy"` | Upload proxy image repository |
| images.uploadProxy.tag | string | Chart's app version | Upload proxy image tag |

### CDI

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cdi.name | string | `"cdi"` | Name of the CDI resource |
| cdi.cloneStrategyOverride | string | `""` | Clone strategy override |
| cdi.config.featureGates | list | `["HonorWaitForFirstConsumer","WebhookPvcRendering"]` | CDI config feature gates |
| cdi.config.uploadProxyURLOverride | string | `""` | Upload Proxy URL override |
| cdi.customizeComponents | object | `{}` | Customize components |
| cdi.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for CDI managed images |
| cdi.infra.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | CDI Infrastructure node selector |
| cdi.workload.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | CDI Workload node selector |

### Upload Proxy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| uploadproxy.ingress.enable | bool | `false` | Enable the upload proxy ingress |
| uploadproxy.ingress.className | string | `""` | Ingress class name |
| uploadproxy.ingress.host | string | `""` | Ingress host |
| uploadproxy.ingress.tls | list | `[]` | Ingress TLS configuration |
| uploadproxy.ingress.annotations | object | `{}` | Upload proxy ingress annotations |
| uploadproxy.ingress.labels | object | `{}` | Upload proxy ingress labels |

### Hooks

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hooks.enable | bool | `true` | Enable post-install hooks |
| hooks.image.registry | string | `"docker.io"` | hook image registry |
| hooks.image.repository | string | `"portainer/kubectl-shell"` | hook image repository |
| hooks.image.tag | string | `"2.39.0"` | hook image tag |
| hooks.image.pullPolicy | string | `"IfNotPresent"` | hook image pull policy |
| hooks.timeout | string | `"5m"` | Time to wait for kubevirt CR to be ready |
| hooks.imagePullSecrets | list | `[]` | imagePullSecrets to use for existing secrets |
| hooks.jobLabels | object | `{}` | Job labels to add to the hook job |
| hooks.podLabels | object | `{}` | Pod labels to add to the hook pod |
| hooks.podAnnotations | object | `{}` | Pod annotations to add to the hook pod |
| hooks.podSecurityContext | object | unprivileged | Pod-level security settings |
| hooks.securityContext | object | unprivileged | Security context for the hook pod |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
