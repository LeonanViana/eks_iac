resource "aws_ecr_repository" "repositories" {
  count = length(var.repositories)
  name  = var.repositories[count.index]
  tags  = local.tags
}

data "aws_iam_policy_document" "policy-ecr" {
  statement {
    sid    = "ECR Policys"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:*",
    ]
  }
}

resource "aws_ecr_repository_policy" "policy-ecr" {
  count      = length(var.repositories)
  repository = aws_ecr_repository.repositories[count.index].name
  policy     = data.aws_iam_policy_document.policy-ecr.json
}
