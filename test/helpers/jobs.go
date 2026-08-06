package helpers

import (
	"fmt"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/testing"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WaitForJobPodToSucceed polls the pods created by the named Job (matched on the
// batch.kubernetes.io/job-name label) until one reaches the Succeeded phase, or
// the retry budget is exhausted.
//
// It deliberately asserts on the pod's terminal phase (set by the kubelet the
// moment the container exits 0) rather than the Job's Complete condition. The
// Job condition is written by the job controller in kube-controller-manager,
// whose finalizer-removal / status reconciliation can lag well beyond the wait
// budget on the cluster control plane, producing false test timeouts even though
// the workload itself succeeded.
func WaitForJobPodToSucceed(t testing.TestingT, options *k8s.KubectlOptions, jobName string, retries int, sleepBetweenRetries time.Duration) error {
	filters := metav1.ListOptions{LabelSelector: "batch.kubernetes.io/job-name=" + jobName}
	for i := 0; i < retries; i++ {
		pods, err := k8s.ListPodsE(t, options, filters)
		if err == nil {
			for _, pod := range pods {
				if pod.Status.Phase == corev1.PodSucceeded {
					return nil
				}
			}
		}
		time.Sleep(sleepBetweenRetries)
	}
	return fmt.Errorf("no pod for job %s reached the Succeeded phase after %d retries", jobName, retries)
}
