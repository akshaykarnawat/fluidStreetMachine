import sys
# import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME", "URL", "PORT", "USER", "PASSWORD", "QUERY", "DEST"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/glue/client/get_connection.html
# notes: tried using connection_props to get the username and password, but the execution was taking too long -- so killed the process.
# glue = boto3.client('glue', region_name='us-east-1')
# connection_props = glue.get_connection(Name='database-1-connection', HidePassword=False).get('Connection', {}).get('ConnectionProperties', {})
# glue.close()

_ = (spark.read.format('jdbc')
    .option('driver', 'com.mysql.cj.jdbc.Driver')
    .option('url', args.get('URL'))                 #'jdbc:mysql://database-1.cgqybx2c0nza.us-east-1.rds.amazonaws.com'
    .option('port', args.get('PORT'))               #'3306'
    .option('user', args.get('USER'))               #'admin'
    .option('password', args.get('PASSWORD'))       #'password123'
    .option('dbtable', f"{args.get('QUERY')} AS t") #'(SELECT * FROM test.test_table LIMIT 10) AS t')
    .option('fetchsize', '1000')
    .load()
    .coalesce(1)
    .write
    .format('parquet')
    .mode('overwrite')
    .save(args.get('DEST'))                         #'s3://test-122121/data'
)

job.commit()
