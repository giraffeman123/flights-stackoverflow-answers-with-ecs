resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = merge(
    var.mandatory_tags,
    {
      Name = var.cluster_name
    }
  )
}