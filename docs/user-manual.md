# TechNative Instance Scheduler User Manual

## Purpose

The Instance Scheduler controls when EC2 instances run. It helps reduce
unnecessary compute usage by assigning reusable operating schedules to
instances.

This manual is intended for application operators. Infrastructure deployment,
DNS, Cognito administration, and Terraform configuration are documented in the
project [README](../README.md).

## Terminology

### Period

A period is an operating window containing:

- Weekdays.
- An optional start time.
- A required stop time.
- A timezone.

A normal period starts instances during its configured time window and can
stop them outside that window.

A period without a start time is stop-only. It never starts an instance, but
can stop it after the configured stop time.

### Schedule

A schedule is a named collection of one or more periods. Instances are assigned
to schedules.

### Instance assignment

An assignment is stored on the EC2 instance as:

```text
InstanceScheduler=<schedule-name>
```

The frontend creates, changes, and removes this tag automatically.

### Ignore scheduler override

An ignore override temporarily prevents a scheduled stop while leaving the
regular schedule assigned.

It is stored as:

```text
Ignore_scheduler=<HH:MM> <timezone>
```

For example:

```text
Ignore_scheduler=22:00 Europe/Amsterdam
```

## Signing in

1. Open the scheduler URL provided by your administrator.
2. Sign in using your company email address and Cognito password.
3. On first login, replace the temporary password with a permanent password.

Use **Sign out** in the navigation sidebar when finished.

If access is denied or no account exists, contact the scheduler administrator.

## Recommended first-time workflow

1. Create one or more periods.
2. Create a schedule and select at least one period.
3. Assign that schedule to an EC2 instance.
4. Verify the assignment on the Instances page.

The scheduler evaluates assignments every five minutes. Changes are therefore
not necessarily applied immediately.

## Overview page

The Overview page provides:

- The number of configured schedules.
- Scheduler API status.
- A list of configured schedules.
- A short explanation of the scheduling workflow.

Use this page for a quick status check. Configuration changes are made on the
Schedules, Periods, and Instances pages.

## Managing periods

Open **Periods** from the navigation sidebar.

### Viewing periods

The **View** selector provides:

- **All periods**: shows every period, including unassigned periods.
- A schedule name: shows only periods assigned to that schedule.

The Schedules column shows where each period is used. An unassigned period is
marked **Unassigned**.

Days are displayed from Monday through Sunday.

### Creating an unassigned period

1. Select **All periods**.
2. Select **+ Create period**.
3. Enter a unique period name.
4. Select one or more weekdays.
5. Optionally enter a start time.
6. Enter a stop time.
7. Select the timezone.
8. Select **Save**.

Use an unassigned period when it should be created now and attached to a
schedule later.

### Creating and assigning a period in one step

1. Select a schedule in the **View** selector.
2. Select **+ Create period**.
3. Complete the period fields.
4. Select **Save**.

The new period is created and assigned to the selected schedule.

### Stop-only periods

Leave **Start time** empty to create a stop-only period.

Example:

| Field | Value |
| --- | --- |
| Name | `weekend-stop` |
| Days | `sat`, `sun` |
| Start time | empty |
| Stop time | `20:00` |
| Timezone | `Europe/Amsterdam` |

This period does not start instances. After 20:00 on Saturday and Sunday, it
can produce a stop decision.

### Editing a period

1. Find the period.
2. Select **Edit**.
3. Change weekdays, start time, stop time, or timezone.
4. Select **Update**.

The period name cannot be changed. Create a new period if a different name is
required.

Changes affect every schedule that uses the period.

### Assigning an existing period

1. Select the target schedule.
2. Select **Assign existing**.
3. Choose an available period.
4. Select **Assign**.

Periods already assigned to the schedule are not shown in the available list.

### Removing a period from a schedule

1. Select the schedule.
2. Find the period.
3. Select **Remove**.
4. Confirm the action.

A schedule must retain at least one period. The final period cannot be removed.

Removing a period from a schedule does not delete the period itself.

### Deleting a period

A period can only be deleted when it is not assigned to any schedule.

1. Remove the period from every schedule.
2. Select **All periods**.
3. Find the unassigned period.
4. Select **Delete**.
5. Confirm permanent deletion.

## Managing schedules

Open **Schedules** from the navigation sidebar.

### Creating a schedule

At least one period must already exist.

1. Select **+ New schedule**.
2. Enter a unique schedule name.
3. Select one or more periods.
4. Select **Create schedule**.

Use clear names because the schedule name becomes the value of the
`InstanceScheduler` EC2 tag.

Examples:

- `office-hours`
- `development-weekdays`
- `weekend-coverage`

### Changing a schedule's periods

1. Open **Periods**.
2. Select the schedule in the **View** selector.
3. Use **Assign existing**, **+ Create period**, or **Remove**.

Schedules cannot be left without a period.

### Deleting a schedule

A schedule can only be deleted when it is not assigned to any EC2 instance.

1. Open **Instances** and remove or change every assignment using the schedule.
2. Return to **Schedules**.
3. Find the schedule.
4. Select **Delete**.
5. Confirm permanent deletion.

The Delete button is disabled while the schedule is in use. The backend checks
instance assignments again during deletion, so a schedule cannot be deleted if
another user assigned it in the meantime.

Deleting a schedule does not delete its periods. They remain available under
**All periods** and can be assigned to another schedule.

Schedules originally defined in Terraform can be recreated by a later
infrastructure deployment. Contact the scheduler administrator if a deleted
schedule returns.

## Managing instances

Open **Instances** from the navigation sidebar.

The page displays:

- Instance name and ID.
- Current EC2 state.
- Instance type.
- Availability Zone and private IP address.
- Assigned schedule.
- Ignore scheduler override.

Use **Refresh** to reload the EC2 inventory.

### Calendar view

Use the **Table** and **Calendar** buttons at the top of the Instances page to
switch views.

The Calendar view shows:

- One row for each instance with an assigned schedule.
- A horizontal Monday-through-Sunday timeline.
- Operating windows as bars positioned by weekday and time.
- Stop-only periods as vertical stop markers.
- Period details and timezone when hovering over a bar or marker.
- Active ignore overrides next to the instance.

The search field filters both views. Schedule assignments and ignore overrides
are managed from the Table view.

### Assigning a schedule

1. Find the instance.
2. Select a schedule in the schedule selector.
3. Select **Assign**.
4. Confirm the action.

The frontend adds the `InstanceScheduler` tag to the instance.

### Changing a schedule

1. Select a different schedule.
2. Select **Update**.
3. Confirm the action.

The existing `InstanceScheduler` tag value is replaced.

### Removing a schedule

1. Select **No schedule**.
2. Select **Remove**.
3. Confirm the action.

This removes the `InstanceScheduler` tag. It does not immediately start or stop
the instance.

## Temporarily ignoring scheduled stopping

Use an override when an instance must remain running beyond its normal stop
time.

### Setting an override

1. Find the instance on the Instances page.
2. Select **Set** under **Ignore scheduler**.
3. Enter the local time until which stopping should be ignored.
4. Select the timezone.
5. Select **Save override**.

The assigned schedule remains visible and unchanged.

### Editing an override

1. Select **Edit** next to the current override.
2. Change the time or timezone.
3. Save the override.

### Removing an override

1. Select **Edit** next to the override.
2. Select **Remove override**.
3. Confirm the action.

After an override expires or is removed, the scheduler resumes normal behavior
on its next evaluation. If the instance is outside its operating window, it
may then be stopped.

## Operational behavior

- The scheduler evaluates instances every five minutes.
- An instance must have a valid `InstanceScheduler` tag to be managed.
- A tag referring to a missing schedule is displayed as missing and cannot be
  evaluated correctly.
- Multiple periods can overlap. A start decision from any active period keeps
  the instance in the start path.
- Times are evaluated in each period's configured timezone.
- Stopping an EC2 instance does not eliminate charges for EBS volumes, Elastic
  IP addresses, or other attached resources.

## Troubleshooting

### A recent frontend change is not visible

1. Wait for the CloudFront deployment to complete.
2. Hard-refresh the browser.
3. Ask the administrator to confirm that the latest module revision was
   deployed with `terraform init -upgrade` and `terraform apply`.

### No periods are available when creating a schedule

Create a period first from **Periods** using **All periods**.

### A period cannot be deleted

The period is still assigned to one or more schedules. Check the Schedules
column and remove those assignments first.

### A period cannot be removed from a schedule

It is the schedule's final period. Assign another period before removing it.

### A schedule cannot be deleted

One or more EC2 instances still use the schedule. Open **Instances** and remove
or change those assignments first.

### An instance is missing

Confirm that:

- The instance is in the AWS account and region where the scheduler is
  deployed.
- Its state is pending, running, stopping, or stopped.
- The scheduler role has permission to describe the instance.

### An instance does not follow its schedule

Check:

1. The assigned schedule exists.
2. The period includes the current weekday.
3. Start and stop times use the expected timezone.
4. `Ignore_scheduler` is not active.
5. The scheduler Lambda and EventBridge rule are operating normally.

### The application reports that the API is unavailable

Wait for CloudFront to finish deploying and retry. If the issue continues,
contact the administrator to check API Gateway, Cognito, CloudFront, and the
management Lambda.

## Support information

When reporting a problem, include:

- Frontend URL.
- Page where the issue occurred.
- Instance ID, schedule name, or period name involved.
- Approximate time and timezone of the issue.
- Screenshot or exact error message.

Do not include passwords, Cognito tokens, or other credentials.
