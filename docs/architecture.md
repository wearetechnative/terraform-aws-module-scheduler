# Instance Scheduler architecture

![Instance Scheduler AWS architecture](architecture.png)

The diagram shows the authenticated frontend path, management API, scheduling
engine, and supporting AWS services. The Mermaid diagram below is retained as
an editable text version.

```mermaid
flowchart LR
  user([Administrator<br/>Web browser])

  subgraph edge["DNS, TLS, and edge"]
    r53[Route 53<br/>A / AAAA aliases]
    acm[ACM certificate<br/>us-east-1]
    cf[CloudFront<br/>custom frontend FQDN]
  end

  subgraph identity["Authentication"]
    cognito[Cognito user pool<br/>OAuth 2.0 + PKCE]
  end

  subgraph web["Frontend and management API"]
    s3[(Private S3 bucket<br/>HTML, JavaScript, SVG)]
    api[API Gateway HTTP API<br/>JWT authorizer]
    webLambda[Management Lambda<br/>schedules, periods, EC2 tags]
  end

  subgraph scheduler["Scheduling engine"]
    eventbridge[EventBridge rule<br/>every 5 minutes]
    schedulerLambda[Scheduler Lambda<br/>evaluate schedules]
  end

  subgraph data["Data and managed infrastructure"]
    dynamodb[(DynamoDB<br/>schedules and periods)]
    ec2[EC2 instances<br/>InstanceScheduler and<br/>Ignore_scheduler tags]
    dlq[(Existing SQS DLQ)]
    kms[KMS key and grants]
    iam[IAM roles and policies]
  end

  user -->|scheduler FQDN| r53
  r53 --> cf
  acm -. TLS certificate .-> cf
  cf -->|static content through OAC| s3
  user <-->|managed login| cognito
  cognito -. JWT access token .-> user
  cf -->|/db* and /instances*| api
  cognito -. validates JWT .-> api
  api --> webLambda
  webLambda <-->|CRUD| dynamodb
  webLambda <-->|describe and update tags| ec2

  eventbridge --> schedulerLambda
  schedulerLambda -->|read schedules and periods| dynamodb
  schedulerLambda -->|start, stop, and remove ignore tag| ec2

  webLambda -. failures .-> dlq
  schedulerLambda -. failures .-> dlq
  iam -. permissions .-> webLambda
  iam -. permissions .-> schedulerLambda
  kms -. encryption grants .-> webLambda
  kms -. encryption grants .-> schedulerLambda
```

## Request flows

- CloudFront serves frontend assets from the private S3 bucket through OAC.
- Cognito authenticates users with OAuth 2.0 authorization code and PKCE.
- API Gateway validates JWT access tokens before invoking the management
  Lambda.
- The management Lambda stores schedules and periods and manages EC2 tags.
- EventBridge invokes the scheduler Lambda every five minutes.
- The scheduler Lambda reads DynamoDB and starts or stops EC2 instances.
- Both Lambda functions use the supplied SQS dead-letter queue.

The standalone Mermaid source is available in
[`architecture.mmd`](architecture.mmd).
