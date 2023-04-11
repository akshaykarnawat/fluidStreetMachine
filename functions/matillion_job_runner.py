import json
import urllib3
import time
import boto3
import traceback

from botocore.exceptions import ClientError


http = urllib3.PoolManager()
event_parameters = ["matillion_cred_name", "group", "project", "job", "version"]


def get_secret(secret_name):
    """
    Get secrets for Matillion
    """
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
    group = event.get("group")
    project = event.get("project")
    job = event.get("job")
    version = event.get("version")
    secrets = get_secret(event.get("matillion_cred_name"))
    auth_token = secrets.get("auth_token")

    # run the matillion workflow job
    job_run_id, run_res = None, {}
    try:
        run_response = http.request(
            "POST",
            f"http://matillion.generation.org/rest/v1/group/name/{group}/project/name/{project}/version/name/{version}/job/name/{job}/run",
            headers={"Authorization": f"Basic {auth_token}"},
        )
        run_res = json.loads(run_response.data.decode("utf-8"))
        job_run_id = run_res.get("id")
    except Exception as e:
        traceback.format_exc()
        raise e

    if not job_run_id:
        return {"statusCode": "-99", "errorMsg": "No job run id"}

    # get the job's status and wait until the job is finished
    finished, status_res = False, {}
    while not finished:
        time.sleep(10)
        try:
            status_response = http.request(
                "GET",
                f"http://matillion.generation.org/rest/v1/group/name/{group}/project/name/{project}/task/id/{job_run_id}",
                headers={"Authorization": f"Basic {auth_token}"},
            )
            status_res = json.loads(status_response.data.decode("utf-8"))
            finished = False if status_res.get("state") != "SUCCESS" else True
        except Exception as e:
            traceback.format_exc()
            raise e

    return {"statusCode": 200, "run_response": run_res, "status_response": status_res}
