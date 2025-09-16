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
           
        
    for instance in ec2.instances.all():
        tags = instance.tags
        for tag in tags:
            if tag.get('Key') == 'InstanceScheduler':
                val = tag.get('Value')
                if val: 
                    name_of_schedule = tag.get('Value')
                    print(name_of_schedule)
                    periods_in_schedule = dynamo_db('schedule', name_of_schedule)
                    print(periods_in_schedule)
                    if periods_in_schedule != "item_not_found":
                        instance_started_by_period = None
                        state_list = []
                        for period_p in periods_in_schedule:
                            state = dynamo_db('period', period_p)
                            state_list.append(state)
                            
                        if 'start' in state_list:
                            instance.start()
                            instance_started_by_period = True
                            print(f'Starting the Instance {instance.id}')

                        elif instance_started_by_period != True and 'stop' in state_list:
                            if instance.hibernation_options == {'Configured': True}:
                                instance.stop(Hibernate=True)
                                print(f'Stopping the Instance {instance.id} with Hibernate')
                            else:
                                instance.stop()    
                                print(f'Stopping the Instance {instance.id}')
                    else:
                        print("exiting because no periods found")
                        exit(1)
    return {
                "statusCode" :200,
                "body": "Success!"
            }
        


