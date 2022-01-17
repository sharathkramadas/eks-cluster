resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = true
    subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
    security_group_ids = [aws_security_group.allow_tls.id]
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
  }

  enabled_cluster_log_types = ["authenticator", "audit", "api"]
  # enabled_cluster_log_types = []
  
  depends_on = [
    aws_iam_role_policy_attachment.role_policy_attachment-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.role_policy_attachment-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-nodegroup"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
  # ami_type = "BOTTLEROCKET_x86_64"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # update_config {
  #   max_unavailable = 2
  # }

  # launch_template {
  #   name = aws_launch_template.bottlerocket_lt.name
  #   version = aws_launch_template.bottlerocket_lt.latest_version
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_role-AmazonEC2ContainerRegistryReadOnly,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}