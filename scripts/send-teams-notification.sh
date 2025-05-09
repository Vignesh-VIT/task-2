#!/bin/bash

# Input Parameters
webhook_url="$1"
job_status="$2"
repository_name="$3"
branch_name="$4"
run_id="$5"
run_number="$6"
actor="$7"
terraform_plan_url="${8:-}"
destroy_message="${9:-}"

# Determine the color based on the job status
job_build_status=$(echo "$job_status" | tr '[:upper:]' '[:lower:]')

if [ "$job_build_status" == "success" ]; then
  color="good"
elif [ -n "$destroy_message" ]; then
  color="warning"
else
  color="attention"
fi

# Get the current timestamp (build triggered time)
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Prepare destroy message section if present
destroy_section=""
if [ -n "$destroy_message" ]; then
  destroy_section=',
          {
            "type": "Container",
            "style": "warning",
            "items": [
              {
                "type": "TextBlock",
                "text": "🚨 **DESTRUCTIVE OPERATIONS ALERT**",
                "weight": "bolder",
                "color": "warning",
                "wrap": true
              },
              {
                "type": "TextBlock",
                "text": "'"$destroy_message"'",
                "wrap": true,
                "color": "warning"
              }
            ]
          }'
fi

# Construct the JSON message for Adaptive Card
message_card='{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "content": {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
          {
            "type": "ColumnSet",
            "columns": [
              {
                "type": "Column",
                "width": "auto",
                "items": [
                  {
                    "type": "Image",
                    "style": "person",
                    "url": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
                    "size": "Small",
                    "altText": "GitHub Icon"
                  }
                ]
              },
              {
                "type": "Column",
                "width": "stretch",
                "items": [
                  {
                    "type": "TextBlock",
                    "text": "**'"$actor"'**",
                    "wrap": true
                  },
                  {
                    "type": "TextBlock",
                    "spacing": "none",
                    "text": "**'"$timestamp"'**",
                    "isSubtle": true,
                    "wrap": true
                  }
                ]
              }
            ]
          },
          {
            "type": "TextBlock",
            "text": "GitHub Action Notification - **'"$job_status"'**",
            "weight": "bolder",
            "size": "medium",
            "color": "'"$color"'"
          }'"$destroy_section"',
          {
            "type": "FactSet",
            "facts": [
              {
                "title": "Repository:",
                "value": "'"$repository_name"'"
              },
              {
                "title": "Branch:",
                "value": "'"$branch_name"'"
              },
              {
                "title": "Status:",
                "value": "'"$job_status"'"
              },
              {
                "title": "Triggered By:",
                "value": "'"$actor"'"
              }
            ]
          }
        ],
        "actions": [
          {
            "type": "Action.OpenUrl",
            "title": "View Build Run",
            "url": "https://github.com/'"$repository_name"'/actions/runs/'"$run_id"'",
            "role": "button"
          },
          {
            "type": "Action.OpenUrl",
            "title": "View Terraform Plan",
            "url": "'"$terraform_plan_url"'",
            "role": "button"            
          }
        ]
      }
    }
  ]
}'

# Send the POST request with the message card
curl -X POST "$webhook_url" \
  -H "Content-Type: application/json" \
  -d "$message_card"