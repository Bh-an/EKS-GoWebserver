# EKS Nodegroup
resource "aws_eks_node_group" "private-nodes" {
  depends_on = [ aws_eks_cluster.eks_cluster ]

  cluster_name    = var.cluster_name
  node_group_name = var.nodegroup_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = var.capacity_type
  instance_types  = var.instance_types

  scaling_config {
    desired_size  = var.nodegroup_desired_size
    max_size      = var.nodegroup_max_size
    min_size      = var.nodegroup_min_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    name    = aws_launch_template.eks_node.name
    version = aws_launch_template.eks_node.latest_version
  }

  labels = {
    node = "kubenode02"
  }
}

resource "aws_launch_template" "eks_node" {
  name = "eks_node"

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    cluster_name              = aws_eks_cluster.eks_cluster.name
    apiServerEndpoint          = aws_eks_cluster.eks_cluster.endpoint
    certificateAuthority           = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    cidr = aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr # Pass the CIDR value
    }
  )
  )
}

  


