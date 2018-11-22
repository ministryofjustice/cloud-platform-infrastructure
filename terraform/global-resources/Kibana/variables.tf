locals {
  test_domain = "cloud-platform-test"

  allowed_test_ips = {
    "54.229.250.233/32" = "test-1-a"
    "54.229.139.68/32"  = "test-1-b"
    "34.246.149.106/32" = "test-1-c"
    "54.229.162.84/32" = "test-2-a"
    "52.19.187.71/32"  = "test-2-b"
    "18.202.103.30/32" = "test-2-c"
  }

  live_domain = "cloud-platform-live"

  allowed_live_ips = {
    "52.17.133.167/32"  = "live-0-a"
    "34.247.134.240/32" = "live-0-b"
    "34.251.93.81/32"   = "live-0-c"
  }

  audit_domain = "cloud-platform-audit"

  allowed_audit_ips = "${merge(local.allowed_test_ips, local.allowed_live_ips)}"
}
