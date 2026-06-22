def handler(event, context):    
    import boto3
    import os
    import json
    from datetime import datetime
    from botocore.exceptions import ClientError
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
    table_name=os.environ["TABLENAME"]
    path = event.get('rawPath')
    method = event.get("requestContext", {}).get("http", {}).get("method")

    if method == "OPTIONS":
        return {
            "statusCode": 204,
            "headers": {
                "access-control-allow-origin": "*",
                "access-control-allow-methods": "GET,POST,OPTIONS",
                "access-control-allow-headers": "authorization,content-type"
            },
            "body": ""
        }

    db = boto3.resource('dynamodb')
    dynamodb = boto3.client('dynamodb')
    table = db.Table(table_name)

    def json_response(status_code, body):
        return {
            "statusCode": status_code,
            "headers": {
                "content-type": "application/json",
                "access-control-allow-origin": "*"
            },
            "body": json.dumps(body)
        }

    def add_period_to_schedule(p, s):
        response = dynamodb.get_item(
        TableName = table_name,
        Key={
            'type': {
                'S': 'schedule',
            },
            'name':{
                'S': s,
            }
        }
        )
        print(f'dynamodb response is {response}')
        items = response.get('Item')
        if not items:
            dynamodb.put_item(
                TableName=table_name,
                Item={
                    "type": {"S": "schedule"},
                    "name": {"S": s},
                    "periods": {"SS": [p]}
                }
            )
            return

        item = items.get('periods', {})
        print(f'item is {item}')
        period_list = item.get('SS', [])
        if p not in period_list:
            period_list.append(p)
        print(f'period_list is {period_list}')
        response = dynamodb.update_item(
            TableName = table_name,
            Key={
                'type': {
                    'S': 'schedule',
                },
                'name':{
                    'S': s,
                }
            },
            AttributeUpdates={
                "periods": {
                    "Value": {
                        "SS": period_list
                    }
                }
            }
        )
        print(f'response is {response}')

    def save_period(period):
        dynamodb.update_item(
            TableName=table_name,
            Key={
                "type": {"S": "period"},
                "name": {"S": period["period_name"]}
            },
            AttributeUpdates={
                "begintime": {
                    "Value": {"S": period["begin_time"]}
                },
                "endtime": {
                    "Value": {"S": period["end_time"]}
                },
                "days": {
                    "Value": {"SS": period["selected_days"]}
                },
                "timezone": {
                    "Value": {"S": period["timezone"]}
                }
            }
        )

    def get_period_assignments():
        response = dynamodb.query(
            TableName=table_name,
            KeyConditionExpression="#type = :schedule_type",
            ExpressionAttributeValues={":schedule_type": {"S": "schedule"}},
            ProjectionExpression="#name, periods",
            ExpressionAttributeNames={
                "#type": "type",
                "#name": "name"
            }
        )
        assignments = {}
        for schedule in response.get("Items", []):
            schedule_name = schedule["name"]["S"]
            for period_name in schedule.get("periods", {}).get("SS", []):
                assignments.setdefault(period_name, []).append(schedule_name)
        return assignments

    if path == '/instances':
        ec2 = boto3.client('ec2')
        paginator = ec2.get_paginator('describe_instances')
        instances = []
        for page in paginator.paginate(
            Filters=[
                {
                    "Name": "instance-state-name",
                    "Values": ["pending", "running", "stopping", "stopped"]
                }
            ]
        ):
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):
                    tags = {
                        tag["Key"]: tag.get("Value", "")
                        for tag in instance.get("Tags", [])
                    }
                    instances.append({
                        "instance_id": instance["InstanceId"],
                        "name": tags.get("Name", ""),
                        "state": instance.get("State", {}).get("Name", "unknown"),
                        "instance_type": instance.get("InstanceType", ""),
                        "availability_zone": instance.get(
                            "Placement", {}
                        ).get("AvailabilityZone", ""),
                        "private_ip": instance.get("PrivateIpAddress", ""),
                        "schedule": tags.get("InstanceScheduler", ""),
                        "ignore_scheduler": tags.get("Ignore_scheduler", "")
                    })
        instances.sort(key=lambda item: (
            item["name"].lower(),
            item["instance_id"]
        ))
        return json_response(200, {"instances": instances})

    if path == '/instances/schedule':
        request_body = event.get('body')
        if request_body is None:
            return json_response(400, {"message": "Instance data is required"})

        request_body = json.loads(request_body)
        instance_id = request_body.get("instance_id", "").strip()
        schedule_name = request_body.get("schedule_name", "").strip()
        if not instance_id:
            return json_response(400, {"message": "An instance ID is required"})

        ec2 = boto3.client('ec2')
        try:
            ec2.describe_instances(InstanceIds=[instance_id])
        except ClientError as error:
            if error.response["Error"]["Code"] in {
                "InvalidInstanceID.NotFound",
                "InvalidInstanceID.Malformed"
            }:
                return json_response(404, {"message": "Instance was not found"})
            raise

        if schedule_name:
            schedule_response = dynamodb.get_item(
                TableName=table_name,
                Key={
                    "type": {"S": "schedule"},
                    "name": {"S": schedule_name}
                }
            )
            if not schedule_response.get("Item"):
                return json_response(
                    404,
                    {"message": f'Schedule "{schedule_name}" was not found'}
                )
            ec2.create_tags(
                Resources=[instance_id],
                Tags=[{"Key": "InstanceScheduler", "Value": schedule_name}]
            )
            return json_response(
                200,
                {
                    "message": "schedule assigned",
                    "instance_id": instance_id,
                    "schedule_name": schedule_name
                }
            )

        ec2.delete_tags(
            Resources=[instance_id],
            Tags=[{"Key": "InstanceScheduler"}]
        )
        return json_response(
            200,
            {"message": "schedule removed", "instance_id": instance_id}
        )

    if path == '/instances/ignore':
        request_body = event.get('body')
        if request_body is None:
            return json_response(400, {"message": "Instance data is required"})

        request_body = json.loads(request_body)
        instance_id = request_body.get("instance_id", "").strip()
        ignore_until = request_body.get("ignore_until", "").strip()
        timezone = request_body.get("timezone", "").strip()
        if not instance_id:
            return json_response(400, {"message": "An instance ID is required"})

        ec2 = boto3.client('ec2')
        try:
            ec2.describe_instances(InstanceIds=[instance_id])
        except ClientError as error:
            if error.response["Error"]["Code"] in {
                "InvalidInstanceID.NotFound",
                "InvalidInstanceID.Malformed"
            }:
                return json_response(404, {"message": "Instance was not found"})
            raise

        if ignore_until or timezone:
            if not ignore_until or not timezone:
                return json_response(
                    400,
                    {"message": "Both an ignore time and timezone are required"}
                )
            try:
                datetime.strptime(ignore_until, "%H:%M")
                ZoneInfo(timezone)
            except ValueError:
                return json_response(
                    400,
                    {"message": "Ignore time must use 24-hour HH:MM format"}
                )
            except ZoneInfoNotFoundError:
                return json_response(
                    400,
                    {"message": f'Unknown timezone "{timezone}"'}
                )

            tag_value = f"{ignore_until} {timezone}"
            ec2.create_tags(
                Resources=[instance_id],
                Tags=[{"Key": "Ignore_scheduler", "Value": tag_value}]
            )
            return json_response(
                200,
                {
                    "message": "scheduler override assigned",
                    "instance_id": instance_id,
                    "ignore_scheduler": tag_value
                }
            )

        ec2.delete_tags(
            Resources=[instance_id],
            Tags=[{"Key": "Ignore_scheduler"}]
        )
        return json_response(
            200,
            {"message": "scheduler override removed", "instance_id": instance_id}
        )

    
    if path == '/db':
        response = table.query(
                KeyConditionExpression=boto3.dynamodb.conditions.Key('type').eq('schedule')
            )
        print(response)  
        schedule = []  

        items  = response['Items']
        for item in items:
            item = item.get('name')
            schedule.append(item)
            
        return json_response(200, {'schedules_list': schedule})

    if path == '/db/create_schedule':
        schedule = event.get('body')
        if schedule is None:
            return json_response(400, {"message": "Schedule data is required"})

        schedule = json.loads(schedule)
        schedule_name = schedule.get("schedule_name", "").strip()
        period_names = schedule.get("period_names", [])
        if isinstance(period_names, str):
            period_names = [period_names]
        period_names = list(dict.fromkeys(
            name.strip() for name in period_names if isinstance(name, str) and name.strip()
        ))
        if not schedule_name or not period_names:
            return json_response(
                400,
                {"message": "A schedule name and at least one period are required"}
            )

        period_response = dynamodb.batch_get_item(
            RequestItems={
                table_name: {
                    "Keys": [
                        {
                            "type": {"S": "period"},
                            "name": {"S": period_name}
                        }
                        for period_name in period_names
                    ],
                    "ProjectionExpression": "#name",
                    "ExpressionAttributeNames": {"#name": "name"}
                }
            }
        )
        existing_periods = {
            item["name"]["S"]
            for item in period_response.get("Responses", {}).get(table_name, [])
        }
        missing_periods = [
            period_name
            for period_name in period_names
            if period_name not in existing_periods
        ]
        if missing_periods:
            return json_response(
                404,
                {"message": f'Periods not found: {", ".join(missing_periods)}'}
            )

        try:
            dynamodb.put_item(
                TableName=table_name,
                Item={
                    "type": {"S": "schedule"},
                    "name": {"S": schedule_name},
                    "periods": {"SS": period_names}
                },
                ConditionExpression="attribute_not_exists(#name)",
                ExpressionAttributeNames={"#name": "name"}
            )
        except ClientError as error:
            if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return json_response(
                    409,
                    {"message": f'Schedule "{schedule_name}" already exists'}
                )
            raise

        return json_response(
            201,
            {
                "message": "schedule created",
                "schedule_name": schedule_name,
                "period_names": period_names
            }
        )

    elif path == '/db/periods':
        response = dynamodb.query(
            TableName=table_name,
            KeyConditionExpression="#type = :period_type",
            ExpressionAttributeNames={"#type": "type"},
            ExpressionAttributeValues={":period_type": {"S": "period"}}
        )
        period_list = response.get("Items", [])
        assignments = get_period_assignments()
        for period in period_list:
            period_name = period["name"]["S"]
            period["schedules"] = assignments.get(period_name, [])
        return json_response(200, {"period_list": period_list})

    elif path == '/db/list_periods':
        print(f'the event is {event}')
        schedule = event.get('body')
        try:
            request_body = json.loads(schedule)
            if isinstance(request_body, dict):
                schedule = request_body.get('schedule_name')
            elif isinstance(request_body, str):
                schedule = request_body
        except (TypeError, json.JSONDecodeError):
            pass
        print(schedule)
        if schedule != None:
            response = dynamodb.get_item(
            TableName = table_name,
            Key={
                'type': {
                    'S': 'schedule',
                },
                'name':{
                    'S': schedule,
                }
            }  
            )
            print(f'dynamodb response is {response}')  
        

            items = response.get('Item')
            if not items:
                return json_response(200, {'period_list': []})

            item = items.get('periods', {})
            print(f'item is {item}')
            period = item.get('SS', [])
            print(f'period is {period}')
            list_p = []
            for p in period:
                print(f'period is {p}')
                response_period = dynamodb.get_item(
                TableName = table_name,
                Key={
                    'type': {
                        'S': 'period',
                    },
                    'name':{
                        'S': p,
                    }
                }  
                )
                print(f'response_period is {response_period}')
                period_item = response_period.get('Item')
                if period_item:
                    list_p.append(period_item)
            print(f'list_p is {list_p}')    
        
            return json_response(200, {'period_list': list_p})
        return json_response(400, {"message": "A schedule name is required"})

    elif path == '/db/create_period':
        period = event.get('body')
        if period is not None:
            period = json.loads(period)
            save_period(period)
            return json_response(
                200,
                {"message": "period created", "period_name": period["period_name"]}
            )
        return json_response(400, {"message": "Period data is required"})

    elif path == '/db/update_period':
        period = event.get('body')
        if period is None:
            return json_response(400, {"message": "Period data is required"})

        period = json.loads(period)
        period_name = period.get("period_name", "").strip()
        selected_days = period.get("selected_days", [])
        begin_time = period.get("begin_time", "").strip()
        end_time = period.get("end_time", "").strip()
        timezone = period.get("timezone", "").strip()
        if not all([
            period_name,
            selected_days,
            begin_time,
            end_time,
            timezone
        ]):
            return json_response(
                400,
                {"message": "Name, days, times, and timezone are required"}
            )

        existing_period = dynamodb.get_item(
            TableName=table_name,
            Key={
                "type": {"S": "period"},
                "name": {"S": period_name}
            }
        )
        if not existing_period.get("Item"):
            return json_response(
                404,
                {"message": f'Period "{period_name}" was not found'}
            )

        save_period(period)
        return json_response(
            200,
            {"message": "period updated", "period_name": period_name}
        )

    elif path == '/db/delete_period_definition':
        delete_item = event.get('body')
        if delete_item is None:
            return json_response(400, {"message": "Period data is required"})

        delete_item = json.loads(delete_item)
        period_name = delete_item.get("period_name", "").strip()
        if not period_name:
            return json_response(400, {"message": "A period name is required"})

        schedules = get_period_assignments().get(period_name, [])
        if schedules:
            return json_response(
                409,
                {
                    "message": "Period is still assigned to schedules",
                    "schedules": schedules
                }
            )

        try:
            dynamodb.delete_item(
                TableName=table_name,
                Key={
                    "type": {"S": "period"},
                    "name": {"S": period_name}
                },
                ConditionExpression="attribute_exists(#name)",
                ExpressionAttributeNames={"#name": "name"}
            )
        except ClientError as error:
            if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return json_response(
                    404,
                    {"message": f'Period "{period_name}" was not found'}
                )
            raise
        return json_response(
            200,
            {"message": "period deleted", "period_name": period_name}
        )

    elif path == '/db/assign_period':
        assignment = event.get('body')
        if assignment is not None:
            assignment = json.loads(assignment)
            period_name = assignment.get("period_name")
            schedule_name = assignment.get("schedule_name")
            if not period_name or not schedule_name:
                return json_response(
                    400,
                    {"message": "A period name and schedule name are required"}
                )

            period_response = dynamodb.get_item(
                TableName=table_name,
                Key={
                    "type": {"S": "period"},
                    "name": {"S": period_name}
                }
            )
            if not period_response.get("Item"):
                return json_response(
                    404,
                    {"message": f'Period "{period_name}" was not found'}
                )

            add_period_to_schedule(period_name, schedule_name)
            return json_response(
                200,
                {
                    "message": "period assigned",
                    "period_name": period_name,
                    "schedule_name": schedule_name
                }
            )
        return json_response(400, {"message": "Assignment data is required"})

    elif path == '/db/add_period':
        period=event.get('body')
        print(period)
        if period != None:
            period = json.loads(period)
            save_period(period)
            schedule = period["schedule_name"]
            p_of_schedule = period["period_name"]
            add_period_to_schedule(p_of_schedule, schedule)   
            return json_response(
                200,
                {"message": "period added", "period_name": p_of_schedule}
            )
        return json_response(400, {"message": "Period data is required"})
    elif path == '/db/delete_period':
        delete_item=event.get('body')
        print(delete_item)
        if delete_item != None:
            delete_item = json.loads(delete_item)
            response = dynamodb.get_item(
                TableName = table_name,
                Key={
                    'type': {
                        'S': "schedule"
                    },
                    'name':{
                        'S': delete_item["selected_schedule"]
                    }
                }
            )   
            print(f'dynamodb response is {response}')
            items  = response['Item']
            item = items.get('periods')
            print(f'item is {item}')
            period_list = item.get('SS')
            print(f'period_list is {period_list}')
            period_list.remove(delete_item["period_name"])
            print(f'period_list is {period_list}')
            response = dynamodb.update_item(
                TableName = table_name,
                Key={
                    'type': {
                        'S': "schedule"
                    },
                    'name':{
                        'S': delete_item["selected_schedule"]
                    }
                },
                AttributeUpdates={
                    "periods": {
                        "Value": {
                            "SS": period_list
                        }
                    }
                }
            )
            return json_response(200, {"message": "period removed"})
        return json_response(400, {"message": "Period data is required"})
    else:   
        return {
                "statusCode" :200,
                "body": "nothing found"
                }
