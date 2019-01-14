output "snapshot_id_main_a" {
  value = "${data.aws_ebs_snapshot.ebs_main_a.snapshot_id}"
}

output "snapshot_id_events_a" {
  value = "${data.aws_ebs_snapshot.ebs_events_a.snapshot_id}"
}

output "snapshot_id_main_b" {
  value = "${data.aws_ebs_snapshot.ebs_main_b.snapshot_id}"
}

output "snapshot_id_events_b" {
  value = "${data.aws_ebs_snapshot.ebs_events_b.snapshot_id}"
}

output "snapshot_id_main_c" {
  value = "${data.aws_ebs_snapshot.ebs_main_c.snapshot_id}"
}

output "snapshot_id_events_c" {
  value = "${data.aws_ebs_snapshot.ebs_events_c.snapshot_id}"
}
