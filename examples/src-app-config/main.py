import os
import json
import urllib.request

APP_NAME = os.environ.get('APP_NAME')
ENV_NAME = os.environ.get('ENV_NAME')
CONFIG_NAME = os.environ.get('CONFIG_NAME')
FLAG_NAME = os.environ.get('FLAG_NAME')

def lambda_handler(event, context):
    url = f'http://localhost:2772/applications/{APP_NAME}/environments/{ENV_NAME}/configurations/{CONFIG_NAME}'
    config = urllib.request.urlopen(url).read()
    parsed_config = json.loads(config)
    return f"Hello {parsed_config[FLAG_NAME]['firstName']}!"
