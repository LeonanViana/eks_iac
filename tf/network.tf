resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags       = local.tags
}

####### SUBNETS #######
resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 6, count.index)
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones))
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    "Name"                                     = ""
    "kubernetes.io/cluster/vemmaisapp-dev-eks" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  })
  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "private_subnet" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 6, count.index + 3)
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))
  tags = merge(local.tags, {
    "Name"                                     = ""
    "kubernetes.io/cluster/vemmaisapp-dev-eks" = "shared"
    "kubernetes.io/role/internal-elb"          = "1"
  })
  depends_on = [aws_vpc.vpc]
}

####### NAT GATEWAY #######

resource "aws_eip" "public-ip" {
  domain     = "vpc"
  tags       = local.tags
  depends_on = [aws_internet_gateway.internet-gateway]
}
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.public-ip.id
  subnet_id     = var.subnet_id_1_public
  tags          = local.tags
  depends_on    = [aws_internet_gateway.internet-gateway]
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.tags
}

####### ROUTE TABLE #######
resource "aws_route_table" "route-table" {
  vpc_id     = aws_vpc.vpc.id
  tags       = local.tags
  depends_on = [aws_internet_gateway.internet-gateway]

  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
}

resource "aws_route_table_association" "association-subnet-route-table-pub1" {
  subnet_id      = var.subnet_id_1_public
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "association-subnet-route-table-pub2" {
  subnet_id      = var.subnet_id_2_public
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "association-subnet-route-table-pub3" {
  subnet_id      = var.subnet_id_3_public
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "association-subnet-route-table-priv4" {
  subnet_id      = var.subnet_id_4_private
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "association-subnet-route-table-priv5" {
  subnet_id      = var.subnet_id_5_private
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "association-subnet-route-table-priv6" {
  subnet_id      = var.subnet_id_6_private
  route_table_id = aws_route_table.route-table.id
}


####### OUTPUTS #######
output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}
