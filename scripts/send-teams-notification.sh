#!/bin/bash

# This script sends a notification to Microsoft Teams via webhook
# Usage: ./send-teams-notification.sh <webhook_url> <job_status> <repository_name> <branch_name> <run_id> <run_number> <actor> <terraform_plan_url>

webhook_url="$1"
job_status="$2"
repository_name="$3"
branch_name="$4"
run_id="$5"
run_number="$6"
actor="$7"
terraform_plan_url="${8:-}"

# Set color based on job status
if [ "$job_status" == "success" ]; then
  theme_color="00FF00"  # Green
else
  theme_color="FF0000"  # Red
fi

# Start building JSON message
message_card='{
  "@type": "MessageCard",
  "title": "GitHub Action Notification for '"$repository_name"'",
  "@context": "http://schema.org/extensions",
  "themeColor": "'"$theme_color"'",
  "summary": "Workflow '"$run_number"' finished with status '"$job_status"'",
  "sections": [
    {
      "activityTitle": "*'"$repository_name"' - Workflow Run #'"$run_number"'*",
      "activitySubtitle": "Pipeline is ***'"$job_status"'***",
      "facts": [
        {
          "name": "Repository",
          "value": "'"$repository_name"'"
        },
        {
          "name": "Branch",
          "value": "'"$branch_name"'"
        },
        {
          "name": "Status",
          "value": "'"$job_status"'"
        },
        {
          "name": "Triggered By",
          "value": "'"$actor"'"
        }
      ]
    }
  ],
  "potentialAction": [
    {
      "@type": "OpenUri",
      "name": "View Workflow Run",
      "targets": [
        {
          "os": "default",
          "uri": "https://github.com/'"$repository_name"'/actions/runs/'"$run_id"'"
        }
      ]
    }'

# If terraform_plan_url is provided, append the additional action
if [ -n "$terraform_plan_url" ]; then
  message_card+=',
    {
      "@type": "OpenUri",
      "name": "View Terraform Plan",
      "targets": [
        {
          "os": "default",
          "uri": "'"$terraform_plan_url"'"
        }
      ]
    }'
fi

# Close the JSON
message_card+='
  ]
}'

# Send the notification
curl -H "Content-Type: application/json" -d "$message_card" "$webhook_url"