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
// whose finalizer-removal/status reconciliation can lag well beyond the wait
// budget on the cluster control plane, producing false test timeouts even though
// the workload itself succeeded.
func WaitForJobPodToSucceed(t testing.TestingT, options *k8s.KubectlOptions, jobName string, retries int, sleepBetweenRetries time.Duration) error {
	filters := metav1.ListOptions{LabelSelector: "batch.kubernetes.io/job-name=" + jobName}
	var lastErr error
	for i := 0; i < retries; i++ {
		pods, err := k8s.ListPodsE(t, options, filters)
		switch {
		case err != nil:
			lastErr = err
		case len(pods) == 0:
			lastErr = fmt.Errorf("no pods found for job %s yet", jobName)
		default:
			phases := make([]string, 0, len(pods))
			for _, pod := range pods {
				if pod.Status.Phase == corev1.PodSucceeded {
					return nil
				}
				phases = append(phases, fmt.Sprintf("%s=%s", pod.Name, pod.Status.Phase))
			}
			lastErr = fmt.Errorf("pods not yet Succeeded: %v", phases)
		}
		time.Sleep(sleepBetweenRetries)
	}
	return fmt.Errorf("no pod for job %s reached Succeeded after %d retries; last state: %w", jobName, retries, lastErr)
}
