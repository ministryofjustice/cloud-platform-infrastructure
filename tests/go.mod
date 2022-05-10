module github.com/ministryofjustice/cloud-platform-infrastructure/tests

go 1.15

require (
	github.com/aws/aws-sdk-go v1.27.1
	github.com/go-resty/resty/v2 v2.6.0
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/gruntwork-io/terratest v0.34.4
	github.com/onsi/ginkgo v1.15.0
	github.com/onsi/gomega v1.10.5
	github.com/pkg/errors v0.9.1
	github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring v0.44.1
	github.com/prometheus-operator/prometheus-operator/pkg/client v0.48.1
	github.com/sirupsen/logrus v1.4.2
	github.com/stretchr/testify v1.4.0
	gopkg.in/yaml.v2 v2.3.0
	k8s.io/apimachinery v0.19.3
	k8s.io/client-go v0.19.3
)
