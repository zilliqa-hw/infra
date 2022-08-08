# data "aws_iam_role" "vpc-flow-log" {
#   name = "AWSVPCFlowLog"
# }

#data "aws_security_group" "default" {
#  name = "default"
#}

data "aws_iam_policy_document" "cicd_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${module.aws_info.accounts.core.shared_services.id}:root",
        "arn:aws:iam::${module.aws_info.accounts.root.id}:root"
      ]
    }
  }
}

# Create an IAM role for AWS Support service access
resource "aws_iam_role" "cicd" {
  name               = "ZilliqaCICD"
  assume_role_policy = data.aws_iam_policy_document.cicd_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cicd" {
  role       = aws_iam_role.cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
