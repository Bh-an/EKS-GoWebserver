# Public subnet(s)
resource "aws_subnet" "public_subnet" {
    depends_on = [aws_vpc.vpc]
    vpc_id                  = aws_vpc.vpc.id
    count                   = length(var.public_subnet_cidr)
    cidr_block              = element(var.public_subnet_cidr, count.index)
    availability_zone       = element(var.availability_zones, 0)
    map_public_ip_on_launch = false
    tags = {
      Name                                              = "${var.platform}-${var.environment}-public-subnet-${element(var.availability_zones, (count.index % length(var.availability_zones)))}"
      Platform                                          = "${var.platform}"
      Environment                                       = "${var.environment}"
      "kubernetes.io/role/elb"                          = "1" 
      "kubernetes.io/cluster/${var.cluster_name}"       = "owned"
    }
}

# Private Subnet(s)
resource "aws_subnet" "private_subnet" {
  depends_on = [aws_vpc.vpc]
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, (count.index % length(var.availability_zones)))
  map_public_ip_on_launch = false

  tags = {
    Name                                                = "${var.platform}-${var.environment}-private-subnet-${element(var.availability_zones, (count.index % length(var.availability_zones)))}"
    Platform                                            = "${var.platform}"
    Environment                                         = "${var.environment}"
    "kubernetes.io/role/internal-elb"                   = "1"
    "kubernetes.io/cluster/${var.cluster_name}"         = "owned"

  }
}