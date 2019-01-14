provider "aws" {
  region  = "eu-west-1"
}

locals {
  common_tags = "${map(
    "kubernetes.io/cluster/${var.cluster_restore}", "owned",
    "KubernetesCluster", "${var.cluster_restore}",
    "k8s.io/role/master", "1"
  )}"
}

data "aws_ebs_snapshot" "ebs_main_a" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["a.etcd-main.${var.cluster_snapshots}"]
  }
}

data "aws_ebs_snapshot" "ebs_events_a" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["a.etcd-events.${var.cluster_snapshots}"]
  }
}

data "aws_ebs_snapshot" "ebs_main_b" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["b.etcd-main.${var.cluster_snapshots}"]
  }
}

data "aws_ebs_snapshot" "ebs_events_b" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["b.etcd-events.${var.cluster_snapshots}"]
  }
}

data "aws_ebs_snapshot" "ebs_main_c" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["c.etcd-main.${var.cluster_snapshots}"]
  }
}

data "aws_ebs_snapshot" "ebs_events_c" {
  most_recent = true

  filter {
    name   = "volume-size"
    values = ["20"]
  }

  filter {
    name   = "tag:Name"
    values = ["c.etcd-events.${var.cluster_snapshots}"]
  }
}

resource "aws_ebs_volume" "volume_from_snapshot_main_a" {
  availability_zone = "eu-west-1a"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_main_a.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "a.etcd-main.${var.cluster_restore}",
      "k8s.io/etcd/main", "a/a,b,c"
    )
  )}"
}

resource "aws_ebs_volume" "volume_from_snapshot_events_a" {
  availability_zone = "eu-west-1a"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_events_a.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "a.etcd-events.${var.cluster_restore}",
      "k8s.io/etcd/events", "a/a,b,c"
    )
  )}"
}

resource "aws_ebs_volume" "volume_from_snapshot_main_b" {
  availability_zone = "eu-west-1b"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_main_b.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "b.etcd-main.${var.cluster_restore}",
      "k8s.io/etcd/main", "b/a,b,c"
    )
  )}"
}

resource "aws_ebs_volume" "volume_from_snapshot_events_b" {
  availability_zone = "eu-west-1b"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_events_b.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "b.etcd-events.${var.cluster_restore}",
      "k8s.io/etcd/events", "b/a,b,c"
    )
  )}"
}

resource "aws_ebs_volume" "volume_from_snapshot_main_c" {
  availability_zone = "eu-west-1c"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_main_c.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "c.etcd-main.${var.cluster_restore}",
      "k8s.io/etcd/main", "c/a,b,c"
    )
  )}"
}

resource "aws_ebs_volume" "volume_from_snapshot_events_c" {
  availability_zone = "eu-west-1c"
  snapshot_id       = "${data.aws_ebs_snapshot.ebs_events_c.snapshot_id}"
  size              = 20
  type              = "gp2"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "c.etcd-events.${var.cluster_restore}",
      "k8s.io/etcd/events", "c/a,b,c"
    )
  )}"
}
