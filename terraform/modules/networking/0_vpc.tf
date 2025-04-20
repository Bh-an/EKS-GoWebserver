## VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.platform}-${var.environment}-vpc-${var.region}"
    Platform    = "${var.platform}"
    Environment = "${var.environment}"
  }
}