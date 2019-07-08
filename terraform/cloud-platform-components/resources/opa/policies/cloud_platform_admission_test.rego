package cloud_platform.admission

# generates a redacted AdmissionReview payload (used to mock `input`)
new_admission_review(op, newObject, oldObject) = {
  "kind": "AdmissionReview",
  "apiVersion": "admission.k8s.io/v1beta1",
  "request": {
    "kind": {
      "kind": newObject.kind
    },
    "operation": op,
    "object": newObject,
    "oldObject": oldObject
  }
}
