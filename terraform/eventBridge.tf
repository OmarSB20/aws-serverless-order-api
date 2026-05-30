resource "aws_cloudwatch_event_rule" "pending_orders_rule" {
  name = "pending-orders-rule"
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name
  event_pattern = jsonencode({
    source = ["customer.orders"]
    detail-type = ["OrderPendingDetected"]
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  arn = aws_sns_topic.order_topic.arn
  rule = aws_cloudwatch_event_rule.pending_orders_rule.name
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name
}

resource "aws_cloudwatch_event_bus" "orders_bus" {
  name = "orders-bus"
}