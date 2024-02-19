variable "intents" {
  description = "Intents of the bot"
  type = list(object({
    name             = string
    utterances       = list(string)
    initial_response = string
  }))
}
