import azure.functions as func
import json
import logging
import os
from datetime import datetime, timedelta, timezone
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, LogsQueryStatus
from azure.keyvault.secrets import SecretClient
import requests

def main(mytimer: func.TimerRequest) -> None:
    """
    Timer-triggered function to monitor AutoPot resources for suspicious activities
    Runs every 5 minutes to check for new threats
    """
    utc_timestamp = datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
    
    if mytimer.past_due:
        logging.info('The timer is past due!')
    
    logging.info(f'Security monitor function executed at {utc_timestamp}')
    
    try:
        # Initialize Azure clients
        credential = DefaultAzureCredential()
        workspace_id = os.environ.get('LOG_ANALYTICS_WORKSPACE_ID')
        slack_webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
        
        if not workspace_id:
            logging.error('LOG_ANALYTICS_WORKSPACE_ID not configured')
            return
        
        logs_client = LogsQueryClient(credential)
        
        # Define monitoring queries
        monitoring_queries = {
            'honey_user_activity': {
                'query': '''
                    SigninLogs
                    | where TimeGenerated > ago(5m)
                    | where UserPrincipalName contains "@" and UserPrincipalName contains "autopot"
                    | project TimeGenerated, UserPrincipalName, IPAddress, Location, ResultType, ResultDescription, UserAgent
                    | order by TimeGenerated desc
                ''',
                'severity': 'CRITICAL'
            },
            'sql_access_attempts': {
                'query': '''
                    AzureDiagnostics
                    | where TimeGenerated > ago(5m)
                    | where ResourceProvider == "MICROSOFT.SQL"
                    | where Category == "SQLSecurityAuditEvents"
                    | where action_name_s in ("LOGIN", "LOGOUT", "DATABASE_OBJECT_ACCESS_GROUP")
                    | project TimeGenerated, server_name_s, client_ip_s, server_principal_name_s, action_name_s, succeeded_s, statement_s
                    | order by TimeGenerated desc
                ''',
                'severity': 'HIGH'
            },
            'keyvault_access': {
                'query': '''
                    KeyVaultData
                    | where TimeGenerated > ago(5m)
                    | where OperationName in ("SecretGet", "SecretList", "SecretSet", "SecretDelete")
                    | project TimeGenerated, OperationName, CallerIpAddress, identity_claim_appid_g, id_s, ResultSignature
                    | order by TimeGenerated desc
                ''',
                'severity': 'MEDIUM'
            },
            'web_portal_access': {
                'query': '''
                    AppServiceHTTPLogs
                    | where TimeGenerated > ago(5m)
                    | where CsHost contains "portal-"
                    | summarize RequestCount = count(), UniqueIPs = dcount(CIp), StatusCodes = make_set(ScStatus) by CIp, bin(TimeGenerated, 1m)
                    | where RequestCount > 5
                    | order by TimeGenerated desc
                ''',
                'severity': 'MEDIUM'
            },
            'privilege_escalation': {
                'query': '''
                    AuditLogs
                    | where TimeGenerated > ago(5m)
                    | where OperationName in ("Add member to role", "Add eligible member to role", "Activate role")
                    | project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result
                    | order by TimeGenerated desc
                ''',
                'severity': 'CRITICAL'
            }
        }
        
        # Execute queries and process results
        for query_name, query_config in monitoring_queries.items():
            try:
                logging.info(f'Executing query: {query_name}')
                
                response = logs_client.query_workspace(
                    workspace_id=workspace_id,
                    query=query_config['query'],
                    timespan=timedelta(minutes=5)
                )
                
                if response.status == LogsQueryStatus.SUCCESS:
                    tables = response.tables
                    if tables and len(tables) > 0:
                        rows = tables[0].rows
                        if rows and len(rows) > 0:
                            logging.info(f'Found {len(rows)} suspicious activities for {query_name}')
                            
                            # Process and send alerts
                            process_security_events(query_name, rows, query_config['severity'], slack_webhook_url)
                        else:
                            logging.info(f'No suspicious activities found for {query_name}')
                    else:
                        logging.info(f'No data returned for {query_name}')
                else:
                    logging.error(f'Query failed for {query_name}: {response.status}')
                    
            except Exception as e:
                logging.error(f'Error executing query {query_name}: {str(e)}')
                continue
        
        logging.info('Security monitoring completed successfully')
        
    except Exception as e:
        logging.error(f'Error in security monitor function: {str(e)}')

def process_security_events(event_type, rows, severity, slack_webhook_url):
    """
    Process security events and send notifications
    """
    try:
        # Create summary of events
        event_summary = {
            'event_type': event_type,
            'severity': severity,
            'count': len(rows),
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'events': []
        }
        
        # Process first few events for details (limit to prevent spam)
        max_events = min(5, len(rows))
        for i in range(max_events):
            row = rows[i]
            event_detail = {
                'timestamp': str(row[0]) if len(row) > 0 else 'Unknown',
                'details': [str(cell) for cell in row[1:6]]  # First 5 additional columns
            }
            event_summary['events'].append(event_detail)
        
        # Send Slack notification if webhook is configured
        if slack_webhook_url:
            send_security_alert(event_summary, slack_webhook_url)
        
        logging.info(f'Processed {len(rows)} events for {event_type}')
        
    except Exception as e:
        logging.error(f'Error processing security events for {event_type}: {str(e)}')

def send_security_alert(event_summary, slack_webhook_url):
    """
    Send security alert to Slack
    """
    try:
        severity = event_summary['severity']
        event_type = event_summary['event_type']
        count = event_summary['count']
        
        # Create Slack message
        color_map = {
            'CRITICAL': '#FF0000',
            'HIGH': '#FF6600',
            'MEDIUM': '#FFCC00',
            'LOW': '#00FF00'
        }
        
        emoji_map = {
            'CRITICAL': '🚨',
            'HIGH': '⚠️',
            'MEDIUM': '⚡',
            'LOW': 'ℹ️'
        }
        
        color = color_map.get(severity, '#808080')
        emoji = emoji_map.get(severity, '🔔')
        
        # Format event type for display
        event_display_names = {
            'honey_user_activity': 'Honey User Sign-in Activity',
            'sql_access_attempts': 'SQL Server Access Attempts',
            'keyvault_access': 'Key Vault Access',
            'web_portal_access': 'Web Portal Suspicious Activity',
            'privilege_escalation': 'Privilege Escalation Attempts'
        }
        
        display_name = event_display_names.get(event_type, event_type.replace('_', ' ').title())
        
        slack_message = {
            "text": f"{emoji} AutoPot Security Alert: {display_name}",
            "attachments": [
                {
                    "color": color,
                    "fields": [
                        {
                            "title": "Event Type",
                            "value": display_name,
                            "short": True
                        },
                        {
                            "title": "Severity",
                            "value": severity,
                            "short": True
                        },
                        {
                            "title": "Event Count",
                            "value": str(count),
                            "short": True
                        },
                        {
                            "title": "Detection Time",
                            "value": datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC'),
                            "short": True
                        }
                    ],
                    "footer": "AutoPot Security Monitor",
                    "ts": int(datetime.now(timezone.utc).timestamp())
                }
            ]
        }
        
        # Add event details if available
        if event_summary['events']:
            details_text = ""
            for i, event in enumerate(event_summary['events'][:3]):  # Show first 3 events
                details_text += f"Event {i+1}: {event['timestamp']}\n"
                details_text += f"Details: {', '.join(event['details'][:3])}\n\n"
            
            if len(event_summary['events']) > 3:
                details_text += f"... and {len(event_summary['events']) - 3} more events"
            
            slack_message["attachments"][0]["fields"].append({
                "title": "Recent Events",
                "value": details_text.strip(),
                "short": False
            })
        
        # Send to Slack
        headers = {'Content-Type': 'application/json'}
        response = requests.post(
            slack_webhook_url,
            data=json.dumps(slack_message),
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            logging.info(f'Successfully sent Slack alert for {event_type}')
        else:
            logging.error(f'Failed to send Slack alert: {response.status_code} - {response.text}')
            
    except Exception as e:
        logging.error(f'Error sending security alert: {str(e)}')
