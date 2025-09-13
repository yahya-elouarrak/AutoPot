#!/usr/bin/env python3
"""
Test script for Slack notifications
Run this script to test your Slack webhook integration
"""

import json
import requests
import sys
from datetime import datetime, timezone

def test_slack_notification(webhook_url):
    """Test Slack notification with sample security alert"""
    
    # Sample security alert message
    test_message = {
        "text": "🚨 AutoPot Security Alert - Test Message",
        "attachments": [
            {
                "color": "#FF6600",  # Orange for High severity
                "fields": [
                    {
                        "title": "Alert Type",
                        "value": "Honey User Sign-in Attempt",
                        "short": True
                    },
                    {
                        "title": "Severity",
                        "value": "HIGH",
                        "short": True
                    },
                    {
                        "title": "Source IP",
                        "value": "192.168.1.100",
                        "short": True
                    },
                    {
                        "title": "Time Detected",
                        "value": datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC'),
                        "short": True
                    },
                    {
                        "title": "Description",
                        "value": "Failed login attempt detected for honey user account john.doe@autopot.local",
                        "short": False
                    },
                    {
                        "title": "User Agent",
                        "value": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                        "short": False
                    }
                ],
                "footer": "AutoPot Security Monitor - Test",
                "ts": int(datetime.now(timezone.utc).timestamp())
            }
        ]
    }
    
    try:
        print("🔄 Sending test notification to Slack...")
        
        response = requests.post(
            webhook_url,
            data=json.dumps(test_message),
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        if response.status_code == 200:
            print("✅ Test notification sent successfully!")
            print("📱 Check your Slack channel for the test alert.")
            return True
        else:
            print(f"❌ Failed to send notification: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Error sending notification: {str(e)}")
        return False

def main():
    """Main function to run the test"""
    print("🧪 AutoPot Slack Notification Test")
    print("=" * 40)
    
    if len(sys.argv) != 2:
        print("Usage: python test_slack.py <slack_webhook_url>")
        print("\nExample:")
        print("python test_slack.py https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX")
        sys.exit(1)
    
    webhook_url = sys.argv[1]
    
    if not webhook_url.startswith("https://hooks.slack.com/services/"):
        print("❌ Invalid Slack webhook URL format")
        print("URL should start with: https://hooks.slack.com/services/")
        sys.exit(1)
    
    print(f"🎯 Testing webhook: {webhook_url[:50]}...")
    
    success = test_slack_notification(webhook_url)
    
    if success:
        print("\n✅ Test completed successfully!")
        print("Your AutoPot monitoring system is ready to send Slack notifications.")
    else:
        print("\n❌ Test failed!")
        print("Please check your webhook URL and try again.")
        sys.exit(1)

if __name__ == "__main__":
    main()
