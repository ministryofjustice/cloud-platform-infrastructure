# Using the opa REPL

1. retrieve the authentication token:
  ```
  kubectl -n opa exec -it opa-0123456789-abcde -c mgmt -- cat /authz/mgmt-token
  ```
1. proxy to the api:
  ```
  kubectl -n opa port-forward opa-0123456789-abcde 8080:443
  ```
1. fetch the data:
  ```
  curl -H 'Authorization: Bearer <TOKEN>' -kvs https://localhost:8080/v1/data | jq
  ```

Once you have the data, in the `opa` command line (`opa run`) you can simply set:
```
data.kubernetes = <json-document>
```

The `input` to the policies would be an `AdmissionReview` whose schema you can find [here][admission-review-type]

[admission-review-type]: https://github.com/kubernetes/api/blob/master/admission/v1beta1/types.go#L29

## Running the tests

* Install [opa]
* `cd terraform/cloud-platform-components/resources/opa/policies/`
* `opa test .`

Output should be:

`PASS: 6/6`

(or whatever the number of tests is, when you run them)

Or, using verbose mode:

```
$ opa test -v .
data.cloud_platform.admission.test_ingress_create_allowed: PASS (911.945µs)
data.cloud_platform.admission.test_ingress_create_conflict: PASS (650.541µs)
data.cloud_platform.admission.test_ingress_update_same_host: PASS (742.035µs)
data.cloud_platform.admission.test_ingress_update_new_host: PASS (596.796µs)
data.cloud_platform.admission.test_ingress_update_existing_host: PASS (736.885µs)
data.cloud_platform.admission.test_ingress_update_existing_host_other_namespace: PASS (1.151801ms)
--------------------------------------------------------------------------------
PASS: 6/6
```

[opa]: https://www.openpolicyagent.org/docs/latest/get-started
