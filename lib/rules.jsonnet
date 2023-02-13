//std.manifestYamlDoc((import '../mixin.libsonnet').prometheusRules)
std.manifestYamlDoc({
  apiVersion: 'monitoring.coreos.com/v1',
  kind: 'PrometheusRule',
  metadata: {
    name: 'micrometer.rules',
    namespace: 'monitoring',
    labels: {
      app: 'kube-prometheus-stack',
      'app.kubernetes.io/instance': 'kube-prometheus-stack',
      release: 'kube-prometheus-stack',
    },
  },
  spec: (import '../mixin.libsonnet').prometheusRules,
})
