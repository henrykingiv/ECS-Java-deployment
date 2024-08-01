locals {
  name = "ecs-deployment"
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      name = "${local.name}-vpc"
    }
}
resource "aws_subnet" "publicsub" {
  vpc_id     = aws_vpc.vpc.id
  count = 3
  cidr_block = element(var.public-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${local.name}-public-subnet"
  }
}
resource "aws_subnet" "privatesub" {
  vpc_id     = aws_vpc.vpc.id
  count = 3
  cidr_block = element(var.private-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${local.name}-private-subnet"
  }
}
# creating internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.name}-igw"
  }
}
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-pub-rt"
  }
}
resource "aws_route_table_association" "pubrt-ass" {
  count = 3  
  subnet_id      = aws_subnet.publicsub[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_eip" "eip" {
  # domain   = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.publicsub[0].id

  tags = {
    Name = "${local.name}-natgw"
  }
}  

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "${local.name}-priv-rt"
  }
}

resource "aws_route_table_association" "priv-ass" {
  count = 3  
  subnet_id      = aws_subnet.privatesub[count.index].id
  route_table_id = aws_route_table.private-rt.id
}