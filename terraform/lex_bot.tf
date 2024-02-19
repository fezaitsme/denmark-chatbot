data "aws_partition" "current" {}

resource "aws_iam_role" "test" {
  name = "botens_namn"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test" {
  role       = aws_iam_role.test.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonLexFullAccess"
}

resource "aws_lexv2models_bot" "test" {
  name                        = "denmark_chatbot"
  idle_session_ttl_in_seconds = 60
  role_arn                    = aws_iam_role.test.arn

  data_privacy {
    child_directed = true
  }
}

resource "aws_lexv2models_bot_locale" "test" {
  locale_id                        = "en_US"
  bot_id                           = aws_lexv2models_bot.test.id
  bot_version                      = "DRAFT"
  n_lu_intent_confidence_threshold = 0.7
}

resource "aws_lexv2models_bot_version" "test" {
  bot_id = aws_lexv2models_bot.test.id
  locale_specification = {
    (aws_lexv2models_bot_locale.test.locale_id) = {
      source_bot_version = "DRAFT"
    }
  }
}

resource "aws_lexv2models_intent" "name" {
  for_each = { for idx, intent in var.intents : idx => intent }

  bot_id      = aws_lexv2models_bot.test.id
  bot_version = aws_lexv2models_bot_locale.test.bot_version
  name        = each.value.name
  locale_id   = aws_lexv2models_bot_locale.test.locale_id

  initial_response_setting {
    initial_response {
      message_group {
        message {
          plain_text_message {
            value = each.value.initial_response
          }
        }
      }
    }
  }

  dynamic "sample_utterance" {
    for_each = each.value.utterances
    iterator = each_utterance
    content {
      utterance = each_utterance.value
    }
  }
}
