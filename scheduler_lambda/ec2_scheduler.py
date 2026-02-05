def handler(event, context):
    import boto3
    import os
    from datetime import datetime, timedelta
    from zoneinfo import ZoneInfo
    from dateutil import tz        
    ec2 = boto3.resource('ec2')
    table_name = os.environ["TABLE_NAME"]
    

    def fetch_item(f, item):
        if f in item:
            new = item.get(f)
            for key, value in new.items(): 
             return(value)
        else:
            return('not_found')    

    def dynamo_db(type, name):
        db = boto3.client('dynamodb')
        response = db.get_item(
        TableName = table_name,
        Key={
            'type': {
                'S': type,
            },
            'name':{
                'S': name,
            }
        }  
        )

        if type == 'schedule':
            item = response.get('Item')
            if item:
                periods = item.get('periods')
                print(periods)
                results = []
                if periods == None:
                    return('item_not_found')
                for key, value in periods.items():
                    period = value
                
                    for period_p in period:     
                
                        results.append(period_p)
                    return results
            else:
                return('item_not_found')           
             
        if type == 'period':
            
            day = datetime.now().strftime('%a')
            day = day.lower()
            
            item = response.get('Item')
            print(f'the response of the period is this {item}')
            days = fetch_item('days', item)
            timezone = fetch_item('timezone', item)
            if timezone == "not_found":
                timezone = "UTC"
            begintime = fetch_item('begintime', item)
            endtime = fetch_item('endtime', item) 
       
            if day in days: 
                currenttime = datetime.now(ZoneInfo(timezone)).time()
                endtime = datetime.strptime(endtime, "%H:%M").time()
                currenttime = currenttime.hour * 3600 +currenttime.minute * 60 + currenttime.second
                endtime = endtime.hour * 3600 + endtime.minute * 60 +  endtime.second
                if begintime == "":
                    if currenttime >= endtime:
                        print("No begin time")
                        return('stop')
                      
                else:   
                    begintime = datetime.strptime(begintime, "%H:%M").time()
                    begintime = begintime.hour * 3600 + begintime.minute * 60 + begintime.second
                    time_diff = (currenttime - begintime)
                    
                    if currenttime >= begintime and endtime>=currenttime:
                                
                        print("Instance should be started")
                        return 'start'
                        
                    else:
                        return('stop')
                        print('not starting')

    def delete_tag(instance_id):
        client = boto3.client('ec2')
        response = client.delete_tags(
            Resources=[
                instance_id,
            ],
            Tags=[
                {
                    'Key': "Ignore_scheduler",
                },
            ]
        )
        print(response)                    
           
        
    for instance in ec2.instances.all():
        tags = instance.tags
        tag_list = []
        for tag in tags:
            tag_list.append(tag)
        print(tag_list)
       # if tag.get('Key') == 'InstanceScheduler':
        if any(tag["Key"] == "InstanceScheduler" for tag in tag_list):
            for tag_key in tag_list:
                if tag_key.get("Key") == "InstanceScheduler":
                    val = tag_key.get("Value")
                    
            if val:    
                name_of_schedule = val
                print(name_of_schedule)
                periods_in_schedule = dynamo_db('schedule', name_of_schedule)
                print(periods_in_schedule)
                if periods_in_schedule != "item_not_found":
                    instance_started_by_period = None
                    state_list = []
                    for period_p in periods_in_schedule:
                        state = dynamo_db('period', period_p)
                        state_list.append(state)
                        print(state_list)
                
                    if 'start' in state_list:
                        instance.start()
                        instance_started_by_period = True
                        print(f'Starting the Instance {instance.id}')

                    elif instance_started_by_period != True and 'stop' in state_list:
                        print(f'tag list: {tag_list}')
                        if any(tag["Key"] == "Ignore_scheduler" for tag in tag_list):
                            print("Ignore tag Found")
                            # ignore_until = tag_key.get("Ignore_scheduler") for tag_key in tag_list if "Ignore_scheduler" in tag_key
                            for tag_key in tag_list:
                                if tag_key.get("Key") == "Ignore_scheduler":
                                    ignore_until = tag_key.get("Value")
                            print(f'ignore_until: {ignore_until}')
                            print(type(ignore_until))
                            ignore_until_list = ignore_until.split()
                            print(f'ignore_until_list: {ignore_until_list}')
                            timezone = ignore_until_list[1]
                            ignore_until = ignore_until_list[0]
                            print(f'ignore_until: {ignore_until}')
                            print(f'timezone: {timezone}')
                            ignore_until = datetime.strptime(ignore_until, "%H:%M").time()
                            ignore_until = ignore_until.hour * 3600 + ignore_until.minute * 60 + ignore_until.second
                            currenttime = datetime.now(ZoneInfo(timezone)).time()
                            currenttime = currenttime.hour * 3600 +currenttime.minute * 60 + currenttime.second
                            if currenttime >= ignore_until:
                                delete_tag(instance.id)

                        else:   
                            print("No Ignore tag Found")         
                            if instance.hibernation_options=={'Configured': True}:
                                instance.stop(Hibernate=True)
                                print(f'Stopping the Instance {instance.id} with Hibernate')
                            else:
                                instance.stop()    
                                print(f'Stopping the Instance {instance.id}')
                else:
                    print("exiting because no periods found")
                    
    return {
                "statusCode" :200,
                "body": "Success!"
            }
        


