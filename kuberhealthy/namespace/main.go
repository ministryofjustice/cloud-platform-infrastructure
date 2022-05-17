package main

import (
	"log"

	"github.com/kuberhealthy/kuberhealthy/v2/pkg/checks/external/checkclient"
)

var debug = true

func main() {
	ok, err := namespaceExist()
	if err != nil {
		log.Println("Namespace check failed:", err)
	}

	if !ok {
		checkclient.ReportFailure([]string{"Namespace check failed"})
		return
	}
	checkclient.ReportSuccess()
}

func namespaceExist() (bool, error) {
	return true, nil
}
