# aws-core-shared-services

Terraforming the Core OU - Shared Services AWS account.

- Route 53 (DNS): `mongodb.hu` . The NS records for subdomains
  are created by the relevant accounts. E.g. `dev.mongodb.hu` is
  created from the `aws-engineering-dev`. If you are in doubt how a resource
  got there, check the AWS resource's tags for the responsible Terraform
  directory.
