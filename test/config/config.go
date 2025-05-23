package config

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/ministryofjustice/cloud-platform-go-library/client"
	kubeErr "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Config holds the basic structure of test's YAML file
type Config struct {
	// Client is a cloud-platform-go-library struct that essentially gives you a kubernetes.Interface
	// to interact with the cluster.
	Client client.KubeClient
	// ClusterName is obtained either by argument or interpolation from a node label.
	ClusterName string `yaml:"clusterName"`
	// Services is a slice of services names only. There is no requirement
	// to hold the whole service object in memory.
	Services []string `yaml:"expectedServices"`
	// Daemonsets is a slice of daemonset names only.
	Daemonsets []string `yaml:"expectedDaemonSets"`
	// ServiceMonitors is a hashmap of [namespaces]ServiceMonitors.string
	// The Prometheus client requires a namespace to perform the lookup,
	// as per the namespace key.
	ServiceMonitors map[string][]string `yaml:"expectedServiceMonitors"`
	// Namespaces defines the names of namespaces. This is used for simple looping.
	Namespaces []string `yaml:"namespaces"`
	// Prefix defines the prefix string used before objects names.
	Prefix string
	// PrometheusRules defines the Prometheus rules that are expected to be in the cluster.
	PrometheusRules []string `yaml:"prometheusRules"`
	// CustomResourceDefinitions defines the CustomResourceDefinitions that are expected to be in the cluster.
	CustomResourceDefinitions []string `yaml:"customResourceDefinitions"`
}

// NewConfig returns a new Config with values passed in.
func NewConfig(clusterName string, services []string, daemonsets []string, serviceMonitors map[string][]string, namespaces []string, prefix string) *Config {
	return &Config{
		ClusterName:     clusterName,
		Services:        services,
		Daemonsets:      daemonsets,
		ServiceMonitors: serviceMonitors,
		Namespaces:      namespaces,
	}
}

// SetClusterName is a setter method to define the name of the cluster to work on.
func (c *Config) SetClusterName(cluster string) error {
	if cluster == "" {
		nodes, err := c.Client.Clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})
		if err != nil {
			return fmt.Errorf("unable to fetch node name: %e", err)
		}

		clusterName := nodes.Items[0].Labels["Cluster"]

		// All Cloud Platform clusters are tagged with the label Cluster=<ClusterName>.
		c.ClusterName = clusterName
	}

	if c.ClusterName != "" {
		return nil
	}

	return errors.New("unable to locate cluster from kubeconfig file")
}

// ExpectedCrds returns a slice of all the CustomResourceDefinitions expected in a cluster. We only need the name of the CRDS here.
func (c *Config) ExpectedCrds() {
	c.CustomResourceDefinitions = append(c.CustomResourceDefinitions,
		"alertmanagerconfigs.monitoring.coreos.com",
		"alertmanagers.monitoring.coreos.com",
		"certificaterequests.cert-manager.io",
		"certificates.cert-manager.io",
		"challenges.acme.cert-manager.io",
		"clusterissuers.cert-manager.io",
		"issuers.cert-manager.io",
		"orders.acme.cert-manager.io",
		"probes.monitoring.coreos.com",
		"prometheuses.monitoring.coreos.com",
		"prometheusrules.monitoring.coreos.com",
		"podmonitors.monitoring.coreos.com",
		"prometheuses.monitoring.coreos.com",
		"prometheusrules.monitoring.coreos.com",
		"thanosrulers.monitoring.coreos.com",
		"servicemonitors.monitoring.coreos.com",
		"bgpconfigurations.crd.projectcalico.org",
		"bgppeers.crd.projectcalico.org",
		"blockaffinities.crd.projectcalico.org",
		"clusterinformations.crd.projectcalico.org",
		"felixconfigurations.crd.projectcalico.org",
		"globalnetworkpolicies.crd.projectcalico.org",
		"globalnetworksets.crd.projectcalico.org",
		"hostendpoints.crd.projectcalico.org",
		"ipamblocks.crd.projectcalico.org",
		"ippools.crd.projectcalico.org",
		"networkpolicies.crd.projectcalico.org",
		"networksets.crd.projectcalico.org",
		"tigerastatuses.operator.tigera.io",
		"kubecontrollersconfigurations.crd.projectcalico.org",
		"ipreservations.crd.projectcalico.org",
		"ipamconfigs.crd.projectcalico.org",
		"installations.operator.tigera.io",
		"imagesets.operator.tigera.io",
		"caliconodestatuses.crd.projectcalico.org",
		"apiservers.operator.tigera.io",
		"ipamhandles.crd.projectcalico.org",
		"assign.mutations.gatekeeper.sh",
		"assignimage.mutations.gatekeeper.sh",
		"assignmetadata.mutations.gatekeeper.sh",
		"configs.config.gatekeeper.sh",
		"constraintpodstatuses.status.gatekeeper.sh",
		"constrainttemplatepodstatuses.status.gatekeeper.sh",
		"constrainttemplates.templates.gatekeeper.sh",
		"expansiontemplate.expansion.gatekeeper.sh",
		"expansiontemplatepodstatuses.status.gatekeeper.sh",
		"k8sexternaldnsidentifier.constraints.gatekeeper.sh",
		"k8sexternaldnsweight.constraints.gatekeeper.sh",
		"k8shostnamelength.constraints.gatekeeper.sh",
		"k8singressclash.constraints.gatekeeper.sh",
		"k8smodsecnginxclass.constraints.gatekeeper.sh",
		"k8smodsecsnippetnginxclass.constraints.gatekeeper.sh",
		"k8srequiredlabels.constraints.gatekeeper.sh",
		"k8sservicetypeloadbalancer.constraints.gatekeeper.sh",
		"k8ssnippetallowlist.constraints.gatekeeper.sh",
		"k8svalidhostname.constraints.gatekeeper.sh",
		"k8swarnserviceaccountsecretdelete.constraints.gatekeeper.sh",
		"modifyset.mutations.gatekeeper.sh",
		"mutatorpodstatuses.status.gatekeeper.sh",
		"providers.externaldata.gatekeeper.sh",
	)
}

// ExpectedPromRules returns a slice of all the Prometheus rules expected in a cluster
func (c *Config) ExpectedPromRules() {
	c.PrometheusRules = append(c.PrometheusRules,
		"prometheus-operator-custom-alerts-node.rules",
		"ingress-controller-apps.rules",
		"prometheus-operator-custom-kubernetes-apps.rules",
		"prometheus-operator-kube-p-alertmanager.rules",
		"prometheus-operator-kube-p-config-reloaders",
		"prometheus-operator-kube-p-k8s.rules.container-cpu-usage-second",
		"prometheus-operator-kube-p-k8s.rules.container-memory-cache",
		"prometheus-operator-kube-p-k8s.rules.container-memory-rss",
		"prometheus-operator-kube-p-k8s.rules.container-memory-swap",
		"prometheus-operator-kube-p-k8s.rules.container-memory-working-s",
		"prometheus-operator-kube-p-k8s.rules.container-resource",
		"prometheus-operator-kube-p-k8s.rules.pod-owner",
		"prometheus-operator-kube-p-kube-apiserver-availability.rules",
		"prometheus-operator-kube-p-kube-apiserver-burnrate.rules",
		"prometheus-operator-kube-p-kube-apiserver-histogram.rules",
		"prometheus-operator-kube-p-kube-apiserver-slos",
		"prometheus-operator-kube-p-kube-prometheus-general.rules",
		"prometheus-operator-kube-p-kube-prometheus-node-recording.rules",
		"prometheus-operator-kube-p-kube-state-metrics",
		"prometheus-operator-kube-p-kubelet.rules",
		"prometheus-operator-kube-p-kubernetes-resources",
		"prometheus-operator-kube-p-kubernetes-storage",
		"prometheus-operator-kube-p-kubernetes-system",
		"prometheus-operator-kube-p-kubernetes-system-apiserver",
		"prometheus-operator-kube-p-kubernetes-system-kubelet",
		"prometheus-operator-kube-p-node-exporter",
		"prometheus-operator-kube-p-node-exporter.rules",
		"prometheus-operator-kube-p-node-network",
		"prometheus-operator-kube-p-node.rules",
		"prometheus-operator-kube-p-prometheus",
		"prometheus-operator-kube-p-prometheus-operator",
	)
}

// ExpectedManagerPromRules returns a slice of additional Prometheus rules expected to be in a manager cluster.
func (c *Config) ExpectedManagerPromRules() {
	c.PrometheusRules = append(c.PrometheusRules,
		"prometheus-operator-manager-custom-kubernetes-apps.rules")
}

// ExpectedNamespaces returns a slice of all the namespaces
// that are expected to be in the cluster.
func (c *Config) ExpectedNamespaces() {
	c.Namespaces = append(c.Namespaces, "cert-manager", "ingress-controllers", "logging", "monitoring", "gatekeeper-system", "velero", "calico-system", "calico-apiserver", "tigera-operator", "trivy-system", "external-secrets-operator", "cloud-platform-label-pods", "kuberos", "kube-system", "default")
}

// ExpectedServices returns a slice of all the Services
// that are expected to be in the cluster.
func (c *Config) ExpectedServices() {
	c.Services = append(c.Services, "cert-manager", "cert-manager-webhook", "prometheus-operated", "alertmanager-operated")

	if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
		c.Services = append(c.Services, "concourse-web", "concourse-worker")
	}
}

// ExpectedDaemonSets populates the 'Daemonsets' object in the 'Config' struct.
func (c *Config) ExpectedDaemonSets() {
	c.Daemonsets = append(c.Daemonsets, "fluent-bit", "prometheus-operator-prometheus-node-exporter", "calico-node", "csi-node-driver", "aws-node", "ebs-csi-node")

	if strings.Contains(strings.ToLower(c.ClusterName), "live") || strings.Contains(strings.ToLower(c.ClusterName), "manager") {
		c.Daemonsets = append(c.Daemonsets, "node-agent")
	}
}

// ExpectedServiceMonitors populates the 'ServiceMonitors' object in the 'Config' struct. A hashmap is used here
// as querying a Prometheus service monitor requires the namespace of the monitor in question. This is less than ideal.
func (c *Config) ExpectedServiceMonitors() {
	// serviceMonitors describes all the service monitors that are expected to be in the cluster and their
	// accompanying namespaces.
	serviceMonitors := map[string][]string{
		// NamespaceName: []Services
		"cert-manager": {"cert-manager"},

		"ingress-controllers": {"nginx-ingress-modsec-controller", "nginx-ingress-default-controller"},

		"logging": {"fluent-bit"},

		"monitoring": {"prometheus-operator-prometheus-node-exporter", "prometheus-operator-kube-p-alertmanager", "prometheus-operator-kube-p-apiserver", "prometheus-operator-kube-p-coredns", "prometheus-operator-grafana", "prometheus-operator-kube-state-metrics", "prometheus-operator-kube-p-kubelet", "prometheus-operator-kube-p-prometheus", "prometheus-operator-kube-p-operator", "prometheus-operator-prometheus-node-exporter"},
	}

	// Manager cluster contains a concourse service. This service doesn't exist on any other cluster (including test)
	if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
		serviceMonitors["concourse"] = []string{"concourse"}
	}

	c.ServiceMonitors = serviceMonitors
}

// Cleanup will look for namespaces with the predefined prefix set and delete them.
// Usually tests will perform this action post-test, so this method acts as a catchall
func (c *Config) Cleanup() error {
	namespaces, err := c.Client.Clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return err
	}

	for _, namespace := range namespaces.Items {
		if strings.Contains(namespace.Name, c.Prefix) {
			err = c.Client.Clientset.CoreV1().Namespaces().Delete(context.TODO(), namespace.Name, metav1.DeleteOptions{})
			if kubeErr.IsNotFound(err) {
				// This is fine, it just means the namespace was already deleted.
				continue
			}
			if err != nil {
				return err
			}
		}
	}

	return nil
}
