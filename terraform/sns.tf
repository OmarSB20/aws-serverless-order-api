resource "aws_sns_topic" "order_topic" {
  name = "orders-topic"
}

# Change the example email for a real one to validate the correct SNS use
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.order_topic.arn
  protocol  = "email"
  endpoint  = "email@example.com"
}