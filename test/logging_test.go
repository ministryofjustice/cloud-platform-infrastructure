package integration_tests

import (
	"context"
	"fmt"
	"io"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Logging tests define the ability for Cloud Platform to perform aggregated logging
// on the platform. The tests are designed to be run in a Kubernetes cluster, with a logging agent installed.
var _ = Describe("logging", Serial, func() {
	Context("when an app generates a log message", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
		)

		var (
			elasticSearch = "https://search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
			date          = time.Now().Format("2006.01.02")
			search        = elasticSearch + "/" + c.ClusterName + "_kubernetes_cluster" + "-" + date + "/_search"
		)

		BeforeEach(func() {
			if !(c.ClusterName == "live") && !(c.ClusterName == "manager") {
				Skip(fmt.Sprintf("Logs don't go to elasticsearch for cluster: %s", c.ClusterName))
			}

			// Create a helloworld app
			namespace = fmt.Sprintf("%s-logs-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)
			host := fmt.Sprintf("%s.%s", namespace, testDomain)

			nsObject := metav1.ObjectMeta{
				Name: namespace,
				Labels: map[string]string{
					"pod-security.kubernetes.io/enforce": "restricted",
				},
			}

			err := k8s.CreateNamespaceWithMetadataE(GinkgoT(), options, nsObject)
			Expect(err).ToNot(HaveOccurred())
			class := "default"

			setIdentifier := "integration-test-app-ing-" + namespace + "-green"
			helloVar := map[string]interface{}{
				"namespace": namespace,
				"host":      host,
				"class":     class,
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", helloVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			// Create a job that creates a simple log message.
			jobVar := map[string]interface{}{
				"jobName":   "logging-smoketest",
				"namespace": namespace,
			}

			tpl, err = helpers.TemplateFile("./fixtures/helloworld-job.yaml.tmpl", "helloworld-job.yaml.tmpl", jobVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			// Wait for the job to complete
			err = k8s.WaitUntilJobSucceedE(GinkgoT(), options, "logging-smoketest", 10, 20*time.Second)
			Expect(err).ToNot(HaveOccurred())

			// Create a job to get the logs from the logging platform.
			searchVar := map[string]interface{}{
				"jobName":    "logging-search",
				"searchTerm": search,
				"namespace":  namespace,
			}

			tpl, err = helpers.TemplateFile("./fixtures/logging-job.yaml.tmpl", "logging-job.yaml.tmpl", searchVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			// Wait for the job to complete
			err = k8s.WaitUntilJobSucceedE(GinkgoT(), options, "logging-search", 10, 20*time.Second)
			Expect(err).ToNot(HaveOccurred())
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).ToNot(HaveOccurred())
		})

		It("should be able to retrieve the log message", func() {
			var podName string

			// To get the pod name, we need to first get all pods in the namespace.
			podList, err := k8s.ListPodsE(GinkgoT(), options, metav1.ListOptions{})
			Expect(err).ToNot(HaveOccurred())
			// and then iterate through the pods to find the one that has the job name.
			for _, pod := range podList {
				if strings.Contains(pod.Name, "logging-search") {
					podName = pod.Name
				}
			}

			// With the pod name, we can get the required logs and assert the output.
			req := c.Client.Clientset.CoreV1().Pods(namespace).GetLogs(podName, &v1.PodLogOptions{
				Container: "smoketest-logging",
			})
			logs, err := req.Stream(context.TODO())
			Expect(err).ToNot(HaveOccurred())
			defer logs.Close()

			// Read the logs
			buf := new(strings.Builder)
			_, err = io.Copy(buf, logs)
			Expect(err).ToNot(HaveOccurred())

			// Check the logs for the expected message
			Expect(buf.String()).To(ContainSubstring("100"))
		})
	})
})
