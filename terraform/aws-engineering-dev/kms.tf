# resources = ["*"] is required to avoid circular dependency.
# This is a policy document attached to the KMS key, so the "*"
# is going to be ignored, but it is required to provide a valid
# policy document.
data "aws_iam_policy_document" "kms_default" {
  statement {
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition.partition}:iam::${local.caller_identity.account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:Encrypt"
    ]

    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
      ]
    }
    resources = ["*"]
  }
}

locals {
  kms_keys = {
    eks = {}
  }
}

resource "aws_kms_key" "keys" {
  for_each                = local.kms_keys
  description             = "Default KMS key for ${each.key}"
  deletion_window_in_days = 7
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.kms_default.json
}

resource "aws_kms_alias" "keys" {
  for_each      = local.kms_keys
  name          = "alias/zilliqa/default/${each.key}"
  target_key_id = aws_kms_key.keys[each.key].key_id
}
