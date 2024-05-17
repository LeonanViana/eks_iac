resource "aws_eks_cluster" "cluster-eks" {
  name     = "${local.prefix}-eks"
  role_arn = aws_iam_role.eks-iam-role.arn
  version  = "1.29"
  tags     = local.tags

  vpc_config {
    subnet_ids = [var.subnet_id_1_public, var.subnet_id_2_public, var.subnet_id_3_public, var.subnet_id_4_private, var.subnet_id_5_private, var.subnet_id_6_private]
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
    aws_vpc.vpc
  ]
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.cluster-eks.name
  node_group_name = "${local.prefix}-worker-node-group"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [var.subnet_id_1_public, var.subnet_id_2_public, var.subnet_id_3_public]
  version         = "1.29"
  ami_type        = var.ami_type
  instance_types  = [var.instance_type]
  tags            = local.tags

  scaling_config {
    desired_size = var.scaling_config_desired_size
    max_size     = var.scaling_config_max_size
    min_size     = var.scaling_config_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_eks_cluster.cluster-eks
  ]
}
