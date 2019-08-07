# cloud-platform-smoke-tests

Smoke tests for kubernetes clusters

Tests tagged 'cluster:live-1' will only work if the current kubernetes config points to the live-1 cluster.

## How to run smoke-tests
The smoke tests will run inside a docker container against your current Kubernetes context (you can see your context by running `kubectl config get-contexts`).

### Pre requisites
- `git`
- `docker`
- `cluster-admin` access to a Cloud Platform cluster

### Build or pull the image
You'll need to have pulled the image locally, you can do this with the following:

#### Pull
- `docker pull ministryofjustice/cloud-platform-smoke-tests:1.0`
-
#### Build
- git clone the [smoke-tests]() repository.
- run `make build`

### Run tests
The smoke tests are separated into three sections.

#### All tests
make tests will run every rspec test in the `spec` directory.
- `make test`

#### Test live-1
make live-1 will only run live-1 (current live Cloud Platform cluster) specific tests.
- `make test-live-1`

#### Test everything but live-1
make test-non-live-1 will test everything but live-1 and is intended to be run against test clusters only.
- `make test-non-live-1`

