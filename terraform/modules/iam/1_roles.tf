# IAM role for EKS cluster
resource "aws_iam_role" "cluster_role" {
    name = "${var.environment}-eks-role"
    assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
    tags = {
        
        Environment = var.environment
        Platform    = var.platform
        
    }
}

# Policy attachment for AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy_attachment" {
    role    = aws_iam_role.cluster_role.name
    policy_arn = data.aws_iam_policy.eksclusterpolicy.arn
}

# Policy attachment for AmazonEKSServicePolicy
resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy_attachment" {
    role    = aws_iam_role.cluster_role.name
    policy_arn = data.aws_iam_policy.eksservicepolicy.arn
}

# IAM role for node groups
resource "aws_iam_role" "node_group_role" {
    name = "${var.environment}-node-group-role"
    assume_role_policy = data.aws_iam_policy_document.nodegroup_assume_role_policy.json
    tags = {
        
        Environment = var.environment
        Platform    = var.platform
        
    }
}

# Policy attachment for AmazonEKSWorkerNodePolicy
resource "aws_iam_role_policy_attachment" "AmazonEKSNodegroupPolicy_attachment" {
    role    = aws_iam_role.node_group_role.name
    policy_arn = data.aws_iam_policy.eksnodegrouppolicy.arn
}

# Policy attachment for AmazonEKS_CNI_Policy
resource "aws_iam_role_policy_attachment" "AmazonEKSCNIPolicy_attachment" {
    role    = aws_iam_role.node_group_role.name
    policy_arn = data.aws_iam_policy.ekscnipolicy.arn
}

# Policy attachment for AmazonECR_registry_pull
resource "aws_iam_role_policy_attachment" "AmazonECRPolicy_attachment" {
    role    = aws_iam_role.node_group_role.name
    policy_arn = data.aws_iam_policy.ecrpolicy.arn
}