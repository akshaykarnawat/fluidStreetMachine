
import boto3
import json
import snowflake.connector
import traceback
import codecs

from botocore.exceptions import ClientError
from io import BytesIO


event_parameters = ["snowflake_cred_name", "snowflake_warehouse", "snowflake_db", "snowflake_schema", "bucket", "key", "params"]

def get_secret(secret_name):
    region_name = "us-east-1"
    secret_manager = boto3.client("secretsmanager", region_name=region_name)
    try:
        response = secret_manager.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        raise e
    secret = json.loads(response["SecretString"])
    return secret

def validate_event(event):
    """ 
    Verify the event object has all the required parameters 
    """
    if event is None:
        raise TypeError("All job parameters missing")

    for key in event_parameters:
        if key not in event:
            raise KeyError(f"{key} parameter missing")

def lambda_handler(event, context):
    """
    Lambda function handler
    """
    validate_event(event)

    secrets = get_secret(event.get('snowflake_cred_name'))
    warehouse = event.get('snowflake_warehouse')
    database = event.get('snowflake_db')
    schema = event.get('snowflake_schema')
    bucket = event.get('bucket')
    obj_key = event.get('key')
    params = event.get('params') # todo: use params for jinja2 vars later

    # connect to snowflake - set ocsp response cache to /tmp, the only place we can write on lambda
    con = snowflake.connector.connect(
        user=secrets.get('username'),
        password=secrets.get('password'),
        account=secrets.get('account'),
        warehouse=warehouse,
        database=database,
        schema=schema,
        ocsp_response_cache_filename='/tmp/ocsp_response_cache'
        )

    sfqids = []
    try:
        # get the sql file from S3 location
        s3 = boto3.client('s3')
        obj = s3.get_object(Bucket=bucket, Key=obj_key)
        sql_file = obj['Body'].read().decode('utf-8')
        
        # replace the param values here -- fixme: use jinja2 for replacement if possible
        for key in params:
            sql_file = sql_file.replace("{{ %s }}" % key, params.get(key))

        # build sql file stream
        stream = BytesIO(sql_file.encode('utf-8'))
        f = codecs.getreader('utf-8')(stream)

        # execute the sql file stream
        for cur in con.execute_stream(f):
            for ret in cur:
                sfqids.append(cur.sfqid)
                print(cur.sfqid, ret, sep='::')
    
    except Exception as e:
        traceback.format_exc()
        raise e

    con.close()

    return { 
        'statusCode' : 200,
        'sfqids' : sfqids
    }
