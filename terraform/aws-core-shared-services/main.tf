module "aws_info" {
  source = "../modules/aws-info"
  providers = {
    aws = aws.root-us-west-2
  }
}
