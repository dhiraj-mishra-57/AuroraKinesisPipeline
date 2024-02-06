-- ----------------------------------------------------------------
-- Step1. Create an extension for AWS lambda
-- ----------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS aws_lambda CASCADE;

-- ----------------------------------------------------------------
-- Step2. Grant access to your user for the newly created schema
-- ----------------------------------------------------------------

GRANT USAGE ON SCHEMA aws_lambda TO mktpadmin;
GRANT USAGE ON SCHEMA aws_commons TO mktpadmin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA aws_lambda TO mktpadmin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA aws_commons TO mktpadmin;

-- ----------------------------------------------------------------
-- Step3. Create your table
-- ----------------------------------------------------------------

CREATE TABLE public.testing_rds_trigger (
	id int4 NULL,
    name varchar NULL,
    dob date null default now(),
	category varchar NULL,
	company varchar NULL,
	age int4 NULL,
	salary float8,
	created_dt timestamp NULL default now(),
	updated_dt timestamp NULL default now()
);

-- ------------------------------------------------------------------------------------------
-- Step4. Create your Function to convert row data to JSON format
-- Note: here old_ corresponds to old value,
-- this value will only be populated whenever there was update or delete
-- and it will hold null value if the operation performed on the table was insert.
-- ------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.my_json_converter(
	old_id integer,
    old_name text,
    old_dob date,
	old_category text,
	old_company text,
	old_age integer,
	old_salary double precision,
    old_created_dt timestamp without timezone,
    old_updated_dt timestamp without timezone,
	id integer,
    name text,
    dob date,
	category text,
	company text,
	age integer,
	salary double precision,
    created_dt timestamp without timezone,
    updated_dt timestamp without timezone
)
  RETURNS json 
  LANGUAGE PLPGSQL
  AS
$$
declare
	json_payload text;
BEGIN
	select json_build_object(
    old_id , 'old_id',
    old_name , 'old_name',
    old_dob , 'old_dob',
	old_category , 'old_category',
	old_company , 'old_company',
	old_age , 'old_age',
	old_salary , 'old_salary',
    old_created_dt , 'old_created_dt',
    old_updated_dt , 'old_updated_dt',
	id , 'id',
    name , 'name',
    dob , 'dob',
	category , 'category',
	company , 'company',
	age , 'age',
	salary , 'salary',
    created_dt , 'created_dt',
    updated_dt, 'updated_dt'
    ) into json_payload;
	RETURN json_payload;
END;
$$


-- ------------------------------------------------------------------------------------------
-- Step5. Function to invoke your Lambda function
-- This is the function which we will execute whenever insert,
-- update or delete operation is performed.
-- use "new" keyword for new record value
-- use "old" keyword for old record value i.e. before update or delete
-- ------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION public.my_db_trigger_function()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
declare
	my_record record;
BEGIN
	raise notice 'Start my_db_trigger_function';
	SELECT * FROM aws_lambda.invoke(aws_commons.create_lambda_function_arn('arn:aws:lambda:us-east-1:{AccountID}:function:{functionName}')
					,(select public.my_json_converter
                    (old.id, old.name, old.dob, old.category, old.company, old.age, old.salary, old.created_dt,
                    old.updated_dt, new.id, new.name, new.dob, new.category, new.company, new.age, new.salary,
                    new.created_dt,new.updated_dt)), 'Event')
	into my_record;
	raise notice 'End my_db_trigger_function';						
	RETURN NEW;
END;
$$

-- ------------------------------------------------------------------------------------------
-- Step5 Trigger Function that calls external lambda function
-- ------------------------------------------------------------------------------------------

CREATE TRIGGER db_trigger_update AFTER update ON testing_rds_trigger
FOR EACH ROW EXECUTE PROCEDURE my_db_trigger_function();

CREATE TRIGGER db_trigger_insert AFTER insert ON testing_rds_trigger
FOR EACH ROW EXECUTE PROCEDURE my_db_trigger_function();

CREATE TRIGGER db_trigger_delete AFTER delete ON testing_rds_trigger
FOR EACH ROW EXECUTE PROCEDURE my_db_trigger_function();

-- Configuration complete
-- Validate the configuration by performing insert, update and delete operation

------------------------------------------- The End! -------------------------------------------
