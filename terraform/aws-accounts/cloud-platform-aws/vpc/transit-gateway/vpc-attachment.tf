resource "aws_ec2_transit_gateway_vpc_attachment" "cp-live-pttp" {
  transit_gateway_id = "tgw-026162f1ba39ce704" # eu-west-2 TGW
  subnet_ids         = [
    "subnet-07fa62f055b2bcfce",
    "subnet-042d27892b9d249dc", 
    "subnet-008096de384cdb660",
    "subnet-00f8b985158ac4e92", ##EKS-Private eu-west-2a
    "subnet-0b3d11fe60784c57d", ##EKS-Private eu-west-2b
    "subnet-0a55c8052635d4af6"  ##EKS-Private eu-west-2c
    ]
  vpc_id             = "vpc-0726ec279947067f8"

  tags = {
    Name  = "cp-live-pttp"
    Owner = "pttp-mojo-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "cp-live-2-pttp" {
  transit_gateway_id = "tgw-026162f1ba39ce704" # eu-west-2 TGW
  subnet_ids         = [
    "subnet-013ebce75092e9f1a",
    "subnet-04f8b186d9e918447",
    "subnet-0a8637bc986c186a8",
    "subnet-0d16d2d022ea23e16", ##EKS-Private eu-west-2a
    "subnet-07886acb5d0cc285a", ##EKS-Private eu-west-2b
    "subnet-0f9a149a0747de75e"  ##EKS-Private eu-west-2c
    ]
  vpc_id             = "vpc-05f6163cd8616d19c"

  tags = {
    Name  = "cp-live-2-pttp"
    Owner = "pttp-mojo-transit-gateway"
  }
}