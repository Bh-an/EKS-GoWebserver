# EKS assume role policy
data "aws_iam_policy_document" "eks_assume_role_policy" {
    statement {
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = ["eks.amazonaws.com"] 
      }
    }
}

# EKS cluster policy
data "aws_iam_policy" "eksclusterpolicy" {
    arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS service policy
data "aws_iam_policy" "eksservicepolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EC2 (Node group) assume role policy
data "aws_iam_policy_document" "nodegroup_assume_role_policy" {
    statement {
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"] 
      }
    }
}

# EKS node group policy
data "aws_iam_policy" "eksnodegrouppolicy" {
    arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# EKS CNI policy
data "aws_iam_policy" "ekscnipolicy" {
    arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS CNI policy
data "aws_iam_policy" "ecrpolicy" {
    arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}