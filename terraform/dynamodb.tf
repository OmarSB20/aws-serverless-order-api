resource "aws_dynamodb_table" "customer_orders_table" {
  name         = "customer-orders-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key  = "CustomerId"
  range_key = "OrderId"

  attribute {
    name = "OrderId"
    type = "S"
  }

  attribute {
    name = "CustomerId"
    type = "S"
  }

  tags = {
    Environment = "dev"
  }
}

locals {
  orders = {
    order1 = {
      order_id = "100"
      customer_id = "1"
      state       = "PENDING"
    }

    order2 = {
      order_id = "101"
      customer_id = "1"
      state       = "COMPLETED"
    }

    order3 = {
      order_id = "102"
      customer_id = "1"
      state       = "PENDING"
    }

    order4 = {
      order_id = "103"
      customer_id = "2"
      state       = "COMPLETED"
    }
  }
}

resource "aws_dynamodb_table_item" "orders" {
  for_each = local.orders

  table_name = aws_dynamodb_table.customer_orders_table.name
  hash_key   = "CustomerId"
  range_key = "OrderId"

  item = jsonencode({
    OrderId = {
      S = each.value.order_id
    }

    CustomerId = {
      S = each.value.customer_id
    }

    State = {
      S = each.value.state
    }
  })
}