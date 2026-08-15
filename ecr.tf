resource "aws_ecr_repository" "devops_infra_ecr" {
  name                 = "devops_infra_ecr"
  image_tag_mutability = "MUTABLE"
}