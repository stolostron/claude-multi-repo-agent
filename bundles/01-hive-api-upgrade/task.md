# Task Description

* Run `go get github.com/openshift/hive/apis@master`.
* If there is vendor in the project, run `go mod tidy && go mod vendor` and if there is not, only run `go mod tidy`.
* Run checks -- `make build` and `make test`, if any error occurs, try analysis and fix the issue.
* If can't fix the issue, result to failing the task.