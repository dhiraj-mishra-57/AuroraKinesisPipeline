# AuroraKinesisPipeline
This repo contains code for configuring data stream pipeline from Aurora RDS to Kinesis using DBTrigger

Streaming data from Postgres to Kinesis using Database Triggers
In this article we will be configuring on how to stream the data from Aurora Postgres database to kinesis using aws lambda, database trigger.
Why do we need streaming data if we can process the same through batch?
In today's world of data-driven apps, getting instant insights is key to success. In todays world, the power to quickly analyze and take business decisions on the real-time data is a game-changer.
You can find more detailed overview of batch & stream here.
Take a look at these prerequisites before we get started
Aurora RDS Instance: Aurora PostgreSQL 11.9 and higher (including Aurora Serverless v2)
AWS Lambda Function: You can find the function code here.
Amazon Kinesis Stream: we need to create a kinesis stream which is our destination here.

Setting up Aurora PostgreSQL to work with Lambda functions is a multi-step process involving AWS Lambda, Kinesis, IAM, your VPC, and your Aurora PostgreSQL DB cluster. Following, you can find summaries of the necessary steps.
Configure IAM role for PostgreSQL cluster
Create an IAM role for RDS which has access to invoke the aws lambda function. You can attach the "AWSLambdaRole" policy to the role.
Configure your Aurora PostgreSQL cluster
Once your Aurora PostgreSQL cluster is up and running you can attach the IAM role created to the RDS cluster under connectivity & security -> Manage IAM role.
Note: You will have to open port 443 if you are working in your VPC.
Install aws extension on PostgreSQL DB
Connect to your RDS DB using any SQL editor of your choice and execute the below command.
CREATE EXTENSION IF NOT EXISTS aws_lambda CASCADE;
This will create 2 new schema in your PostgreSQL DB i.e. aws_commons & aws_lambda.
Grant users to invoke Lambda function
Before proceeding we need to provide the respective DB user with the usage access on the schema aws_lambda. This will allow users to invoke the lambda function from PostgreSQL.
GRANT USAGE ON SCHEMA aws_lambda TO mktpadmin;
GRANT USAGE ON SCHEMA aws_commons TO mktpadmin;
Configuring the Trigger functions
We need to configure the below functions and DB trigger to complete our configuration
Utility to convert record to JSON format
Function to invole lambda function
DB Trigger on table for insert, update and delete

You can find the entire code here on my GitHub.
Note: use "new" keyword for new record value & similarly "old" keyword for old record value i.e. before update or delete
5. Invoke your Lambda function:
All set, now lets trigger our lambda function from our any SQL editor, by executing the below command.
Note: There are several ways to call the lambda function i.e. Synchronous & Asynchronous
Synchronous (RequestResponse) invocation - 

SELECT * FROM aws_lambda.invoke('aws_lambda_arn_1', '{"body": "Hello from Postgres!"}'::json, 'RequestResponse');
Asynchronous (Event) invocation - Use the Event invocation type in certain workflows that don't depend on the results of the Lambda function.

SELECT * FROM aws_lambda.invoke('aws_lambda_arn_1', '{"body": "Hello from Postgres!"}'::json, 'Event');
How to decide if you want to go with Synchronous or Asynchronous?
You can choose Synchronous trigger if you want to wait for the lambda code to complete before committing the changes to the database. You can choose asynchronous invocation so you don't have to wait for lambda to complete. You can add retry & failure destinations on lambda configuration so you don't lose data.
In Synchronous mode, your update, insert, or delete will only complete after the lambda has finished executing, causing your DB transaction to be delayed.
