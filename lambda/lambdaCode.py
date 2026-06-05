import os
import json
import boto3
from boto3.dynamodb.conditions import Key

from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

ORDERS_TABLE_NAME = os.environ["ORDERS_TABLE_NAME"]
CUSTOMERS_TABLE_NAME = os.environ["CUSTOMERS_TABLE_NAME"]

eventbridge = boto3.client('events')

dynamodb = boto3.resource('dynamodb')
ordersTable = dynamodb.Table(ORDERS_TABLE_NAME)
customersTable = dynamodb.Table(CUSTOMERS_TABLE_NAME)

def lambda_handler(event, context):

    try:
        customer_id = (
            event.get("pathParameters", {})
            .get("customerId")
        )

        if not customer_id:
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Customer Id required"})
            }
        
        items = query_dynamo(customer_id)

        filtered_items = filter_items(items)

        send_eventbridge(filtered_items, customer_id)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "items": filtered_items
            })
        }
    
    except Exception as e:
        print(f"Error: {e}")

        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal Server Error"})
        }

@xray_recorder.capture("query_dynamo")
def query_dynamo(customer_id: str) -> dict:

    try:
        ordersResponse = ordersTable.query(
            KeyConditionExpression=Key('CustomerId').eq(customer_id)
        )

        customerResponse = customersTable.get_item(
            Key={'CustomerId':customer_id}
        )

        customer = customerResponse['Item']

        return {
           "Name": customer["Name"],
           "LastName": customer["LastName"],
           "Orders": ordersResponse["Items"]
        }
    except Exception as e:
        print(f"DynamoDB error: {e}")
        raise

@xray_recorder.capture("filter_items")
def filter_items(item: dict) -> dict:

    return {
        "Name": item["Name"],
        "LastName": item["LastName"],
        "Orders": [
            order
            for order in item["Orders"]
            if order["State"] == "PENDING"
        ]
    }

@xray_recorder.capture("send_eventbridge")
def send_eventbridge(pending_orders: dict, customer_id: str):
    try:
            response = eventbridge.put_events(
                Entries=[
                    {
                        "EventBusName": "orders-bus",
                        "Source": "customer.orders",
                        "DetailType": "OrderPendingDetected",
                        "Detail": json.dumps({
                            "customerId": customer_id,
                            "name": pending_orders["Name"],
                            "lastName": pending_orders["LastName"] ,
                            "ordersId": pending_orders["Orders"]
                        })
                    }
                ]
            )

            return response
    except Exception as e:
        print(f"EventBridge error: {e}")
        raise