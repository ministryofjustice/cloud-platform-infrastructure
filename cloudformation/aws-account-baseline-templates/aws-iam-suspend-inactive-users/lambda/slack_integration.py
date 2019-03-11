#==================================================================================================
# Function: SlackIntegration
# Purpose:  Lambda to Slack Integration
#==================================================================================================
import boto3
import json
import logging
import os

from base64 import b64decode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

slack_channel = os.environ['SLACK_CHANNEL']
slack_hook_url = os.environ['HOOK_URL']

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    message = event['Records'][0]['Sns']['Subject'] + '\n' + event['Records'][0]['Sns']['Message']
    try:
    message = json.loads(message)
    except Exception as e:
    print(e)
    logger.info("Message: " + str(message))
    slack_message = {
        'channel': slack_channel,
        'username': "AWSSlack",
        'text': message,
        'icon_emoji' : ":ghost:"
    }
    req = Request(slack_hook_url, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)