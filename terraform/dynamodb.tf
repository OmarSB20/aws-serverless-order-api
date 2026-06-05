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

resource "aws_dynamodb_table" "customers_table" {
  name = "customers-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "CustomerId"

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

  customers = {
    customer1 = {
      customer_id = "1"
      name = "Roberto"
      last_name = "Jimenez"
    }

    customer2 = {
      customer_id = "2"
      name = "Juan"
      last_name = "Dieguez"
    }
  }
}

resource "aws_dynamodb_table_item" "customers" {
  for_each = local.customers

  table_name = aws_dynamodb_table.customers_table.name
  hash_key = "CustomerId"
  
  item = jsonencode({
    CustomerId = {
      S = each.value.customer_id
    }

    Name = {
      S = each.value.name
    }

    LastName = {
      S = each.value.last_name
    }
  })
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