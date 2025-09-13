import azure.functions as func
import json
import logging
import os
import requests
from datetime import datetime, timezone
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient
from azure.keyvault.secrets import SecretClient

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function to handle Sentinel incident notifications and send to Slack
    """
    logging.info('Slack notifier function triggered')
    
    try:
        # Get configuration from environment variables
        slack_webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
        workspace_id = os.environ.get('LOG_ANALYTICS_WORKSPACE_ID')
        
        if not slack_webhook_url:
            logging.error('SLACK_WEBHOOK_URL not configured')
            return func.HttpResponse("Configuration error", status_code=500)
        
        # Parse the request body (Sentinel incident data)
        try:
            req_body = req.get_json()
        except ValueError:
            logging.error('Invalid JSON in request body')
            return func.HttpResponse("Invalid JSON", status_code=400)
        
        if not req_body:
            logging.error('Empty request body')
            return func.HttpResponse("Empty request body", status_code=400)
        
        # Extract incident information
        incident_data = extract_incident_data(req_body)
        
        # Create Slack message
        slack_message = create_slack_message(incident_data)
        
        # Send to Slack
        response = send_slack_notification(slack_webhook_url, slack_message)
        
        if response.status_code == 200:
            logging.info(f'Successfully sent Slack notification for incident: {incident_data.get("title", "Unknown")}')
            return func.HttpResponse("Notification sent successfully", status_code=200)
        else:
            logging.error(f'Failed to send Slack notification: {response.status_code} - {response.text}')
            return func.HttpResponse(f"Failed to send notification: {response.status_code}", status_code=500)
            
    except Exception as e:
        logging.error(f'Error in slack_notifier function: {str(e)}')
        return func.HttpResponse(f"Internal error: {str(e)}", status_code=500)

def extract_incident_data(req_body):
    """
    Extract relevant incident data from Sentinel webhook payload
    """
    incident_data = {}
    
    # Handle different webhook formats
    if 'data' in req_body and 'essentials' in req_body['data']:
        # Logic App webhook format
        essentials = req_body['data']['essentials']
        incident_data = {
            'title': essentials.get('alertRule', 'Unknown Alert'),
            'severity': essentials.get('severity', 'Unknown'),
            'status': essentials.get('monitorCondition', 'Unknown'),
            'description': essentials.get('description', 'No description available'),
            'fired_time': essentials.get('firedDateTime', datetime.now(timezone.utc).isoformat()),
            'resource_group': essentials.get('essentials', {}).get('resourceGroupName', 'Unknown'),
            'subscription_id': essentials.get('essentials', {}).get('subscriptionId', 'Unknown')
        }
    elif 'WorkspaceId' in req_body:
        # Direct Sentinel incident format
        incident_data = {
            'title': req_body.get('DisplayName', 'AutoPot Security Alert'),
            'severity': req_body.get('Severity', 'Unknown'),
            'status': req_body.get('Status', 'New'),
            'description': req_body.get('Description', 'Suspicious activity detected in AutoPot honeypot'),
            'fired_time': req_body.get('TimeGenerated', datetime.now(timezone.utc).isoformat()),
            'workspace_id': req_body.get('WorkspaceId', ''),
            'incident_id': req_body.get('IncidentNumber', 'Unknown')
        }
    else:
        # Generic format
        incident_data = {
            'title': req_body.get('title', req_body.get('alertRule', 'AutoPot Security Alert')),
            'severity': req_body.get('severity', 'Medium'),
            'status': req_body.get('status', 'New'),
            'description': req_body.get('description', 'Suspicious activity detected in AutoPot honeypot'),
            'fired_time': req_body.get('timestamp', datetime.now(timezone.utc).isoformat()),
            'raw_data': json.dumps(req_body, indent=2)[:500]  # First 500 chars of raw data
        }
    
    return incident_data

def create_slack_message(incident_data):
    """
    Create a formatted Slack message for the incident
    """
    severity = incident_data.get('severity', 'Unknown').upper()
    
    # Determine color based on severity
    color_map = {
        'CRITICAL': '#FF0000',  # Red
        'HIGH': '#FF6600',      # Orange
        'MEDIUM': '#FFCC00',    # Yellow
        'LOW': '#00FF00',       # Green
        'INFORMATIONAL': '#0099FF'  # Blue
    }
    color = color_map.get(severity, '#808080')  # Default gray
    
    # Format timestamp
    try:
        fired_time = datetime.fromisoformat(incident_data.get('fired_time', '').replace('Z', '+00:00'))
        formatted_time = fired_time.strftime('%Y-%m-%d %H:%M:%S UTC')
    except:
        formatted_time = 'Unknown'
    
    # Create emoji based on severity
    emoji_map = {
        'CRITICAL': '🚨',
        'HIGH': '⚠️',
        'MEDIUM': '⚡',
        'LOW': 'ℹ️',
        'INFORMATIONAL': '📊'
    }
    emoji = emoji_map.get(severity, '🔔')
    
    slack_message = {
        "text": f"{emoji} AutoPot Security Alert - {severity} Severity",
        "attachments": [
            {
                "color": color,
                "fields": [
                    {
                        "title": "Alert Title",
                        "value": incident_data.get('title', 'Unknown'),
                        "short": False
                    },
                    {
                        "title": "Severity",
                        "value": severity,
                        "short": True
                    },
                    {
                        "title": "Status",
                        "value": incident_data.get('status', 'Unknown'),
                        "short": True
                    },
                    {
                        "title": "Time Detected",
                        "value": formatted_time,
                        "short": True
                    },
                    {
                        "title": "Description",
                        "value": incident_data.get('description', 'No description available'),
                        "short": False
                    }
                ],
                "footer": "AutoPot Honeypot Monitoring",
                "ts": int(datetime.now(timezone.utc).timestamp())
            }
        ]
    }
    
    # Add additional fields if available
    if 'workspace_id' in incident_data:
        slack_message["attachments"][0]["fields"].append({
            "title": "Workspace ID",
            "value": incident_data['workspace_id'][:8] + "...",  # Truncate for readability
            "short": True
        })
    
    if 'incident_id' in incident_data:
        slack_message["attachments"][0]["fields"].append({
            "title": "Incident ID",
            "value": incident_data['incident_id'],
            "short": True
        })
    
    return slack_message

def send_slack_notification(webhook_url, message):
    """
    Send notification to Slack using webhook
    """
    headers = {
        'Content-Type': 'application/json'
    }
    
    response = requests.post(
        webhook_url,
        data=json.dumps(message),
        headers=headers,
        timeout=30
    )
    
    return response
