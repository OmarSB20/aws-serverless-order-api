import os
import json
import boto3
from boto3.dynamodb.conditions import Key

from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

TABLE_NAME = os.environ["TABLE_NAME"]

eventbridge = boto3.client('eventbridge')

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

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

        response = send_eventbridge(filtered_items, customer_id)

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
def query_dynamo(customer_id: str) -> list:

    try:
        response = table.query(
            KeyConditionExpression=Key('CustomerId').eq(customer_id)
        )

        return response['Items']
    except Exception as e:
        print(f"DynamoDB error: {e}")
        raise

@xray_recorder.capture("filter_items")
def filter_items(items: list) -> list:

    result = []

    for item in items:

        if item["State"] == "PENDING":
            result.append(item["OrderId"])

    return result

@xray_recorder.capture("send_eventbridge")
def send_eventbridge(pending_orders: list, customer_id: str):
    try:
            response = eventbridge.put_events(
                Entries=[
                    {
                        "EventBusName": "orders-bus",
                        "Source": "customer.orders",
                        "DetailType": "OrderPendingDetected",
                        "Detail": json.dumps({
                            "customerId": customer_id,
                            "orderId": pending_orders
                        })
                    }
                ]
            )

            return response
    except Exception as e:
        print(f"EventBridge error: {e}")
        raise