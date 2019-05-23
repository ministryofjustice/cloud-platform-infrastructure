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

The `input` to the policies would be an `AdmissionRequest` whose schema you can find [here][admission-request-type]

[admission-request-type]: https://github.com/kubernetes/api/blob/master/admission/v1beta1/types.go#L29

