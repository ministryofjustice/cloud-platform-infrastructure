# E2E Tests

## Running the tests

To run the end to end tests we must go inside the `e2e/` folder and execute:

```
$ go test -v -config ../config/live.yaml
```

The flag `-config` allow us to specify different configuration files depending on which components we want to test for different clusters.  

### Running individual tests

A neat trick in Ginkgo is to place an "F" in front of the "Describe", "It" or "Context" functions. This marks it as [focused](https://onsi.github.io/ginkgo/#focused-specs).

So, if you have spec like:

```
    It("should be idempotent", func() {
```

You rewrite it as:

```
    FIt("should be idempotent", func() {
```

And it will run exactly that one spec:

```
[Fail] testing Migrate setCurrentDbVersion [It] should be idempotent 
...
Ran 1 of 5 Specs in 0.003 seconds
FAIL! -- 0 Passed | 1 Failed | 0 Pending | 4 Skipped
```
