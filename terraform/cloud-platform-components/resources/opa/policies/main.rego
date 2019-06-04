package system

import data.cloud_platform.admission

main = {
  "apiVersion": "admission.k8s.io/v1beta1",
  "kind": "AdmissionReview",
  "response": response,
}

default response = {"allowed": true}

response = {
    "allowed": false,
    "status": {
        "reason": admission.denied_msg,
    },
} { admission.denied }
