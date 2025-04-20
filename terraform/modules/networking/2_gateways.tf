# Internet Gateway
resource "aws_internet_gateway" "ig" {
  depends_on = [aws_subnet.public_subnet]
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.platform}-${var.environment}-igw"
    Platform    = "${var.platform}"
    Environment = "${var.environment}"
  }
}

# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.ig]
  tags = {
    Name        = "${var.platform}-${var.environment}-nat-eip"
    Platform    = "${var.platform}"
    Environment = "${var.environment}"
  }

}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  depends_on = [aws_eip.nat_eip]
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = {
    Name        = "${var.platform}-${var.environment}-nat-gw"
    Platform    = "${var.platform}"
    Environment = "${var.environment}"
  }
}
