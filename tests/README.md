# E2E Tests

## Running the tests

To run the end to end tests we must go to the `e2e/` folder and execute:

```
$ go test -v -config live.yaml
```

The flag `-config` allow us to specify different configuration files depending on which components we want to test for different clusters.  
