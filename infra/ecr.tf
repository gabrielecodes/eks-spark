resource "aws_ecr_repository" "spark" {
  name                 = "spark_images"
  image_tag_mutability = "IMMUTABLE"

  #   image_scanning_configuration {
  #     scan_on_push = true
  #   }
}
