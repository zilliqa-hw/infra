data "aws_organizations_organization" "org" {}

locals {
  root_domain       = "metricsglobal.dev" # This have to be the AWS Org main domain to run queries against.
  master_account_id = data.aws_organizations_organization.org.master_account_id
  root_account      = data.aws_organizations_organization.org
  aws_accounts = {
    org = data.aws_organizations_organization.org

    root = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+root@${local.root_domain}")]
    core = {
      audit           = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+core-audit@${local.root_domain}")]
      log_archive     = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+core-log-archive@${local.root_domain}")]
      shared_services = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+core-shared-services@${local.root_domain}")]
    }

    engineering = {
      dev  = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+engineering-dev@${local.root_domain}")]
      prod = local.root_account.accounts[index(local.root_account.accounts[*].email, "aws+engineering-prod@${local.root_domain}")]
    }
  }
}
