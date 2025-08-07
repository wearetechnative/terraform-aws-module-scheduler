def handler(event, context):    
    import boto3
    import os
    import json
    table_name=os.environ["TABLENAME"]
    path = event.get('rawPath')
    db = boto3.resource('dynamodb')
    dynamodb = boto3.client('dynamodb')
    table = db.Table(table_name)
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
        items  = response['Item']
        item = items.get('periods')
        print(f'item is {item}')
        period_list = item.get('SS')
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
            
        return {
                "statusCode" :200,
                "body": json.dumps({'schedules_list': schedule})
                } 

    if path == '/db/list_periods':
        print(f'the event is {event}')
        schedule=event.get('body')
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
        

            items  = response['Item']
            item = items.get('periods')
            print(f'item is {item}')
            period = item.get('SS')
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
                if response_period.get('Item') != "<empty>":
                    list_p.append(response_period.get('Item'))
            print(f'list_p is {list_p}')    
        
            return {
                    "statusCode" :200,
                    "body": json.dumps({'period_list': list_p})
                    } 
    elif path == '/db/add_period':
        period=event.get('body')
        print(period)
        if period != None:
            period = json.loads(period)
            response = dynamodb.update_item(
                TableName = table_name,
                Key={
                    'type': {
                        'S': 'period',
                    },
                    'name':{
                        'S': period["period_name"],
                    }
                }, 
                AttributeUpdates={
                    "begintime": {
                        "Value": {
                            "S": period["begin_time"]
                        }
                    },
                    "endtime": {
                        "Value": {
                            "S": period["end_time"]
                        }
                    },
                    "days": {
                        "Value": {
                            "SS": period["selected_days"]
                        }
                    },
                    "timezone": {
                        "Value": {
                            "S": period["timezone"]
                        }
                    }
                }    
            ) 
            schedule = period["schedule_name"]
            p_of_schedule = period["period_name"]
            add_period_to_schedule(p_of_schedule, schedule)   
            return {
                        "statusCode" :200,
                        "body": "success"
                        } 
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
    else:   
        return {
                "statusCode" :200,
                "body": "nothing found"
                }
    
   
               