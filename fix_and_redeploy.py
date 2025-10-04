#!/usr/bin/env python3
"""
Fix the deployment issues and redeploy
"""

import subprocess
import json
import time

def run_command(cmd):
    """Run a command and return the output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            print(f"Error running command: {cmd}")
            print(f"Error output: {result.stderr}")
            return None
    except Exception as e:
        print(f"Exception running command: {cmd}")
        print(f"Exception: {e}")
        return None

def main():
    PROJECT_ID = "spry-scope-473614-v8"
    SERVICE_NAME = "theo-inventory"
    REGION = "us-central1"
    IMAGE_NAME = f"gcr.io/{PROJECT_ID}/{SERVICE_NAME}"
    
    print("🔧 Fixing deployment issues and redeploying...")
    print("=============================================")
    
    # 1. Get access token
    print("📡 Getting access token...")
    token_cmd = f"gcloud auth print-access-token"
    access_token = run_command(token_cmd)
    
    if not access_token:
        print("❌ Failed to get access token")
        return
    
    print("✅ Got access token")
    
    # 2. Build and push new Docker image
    print("\n🏗️ Building new Docker image with fixes...")
    
    # Use Cloud Build to avoid local Docker issues
    build_cmd = f'''gcloud builds submit --tag {IMAGE_NAME} --project={PROJECT_ID}'''
    
    print("Building with Cloud Build...")
    build_result = run_command(build_cmd)
    
    if not build_result:
        print("❌ Failed to build Docker image")
        return
    
    print("✅ Docker image built successfully")
    
    # 3. Update the existing service with new configuration
    print("\n🚀 Updating Cloud Run service...")
    
    # Create updated service configuration
    service_config = {
        "apiVersion": "serving.knative.dev/v1",
        "kind": "Service",
        "metadata": {
            "name": SERVICE_NAME,
            "namespace": PROJECT_ID,
            "annotations": {
                "run.googleapis.com/ingress": "all"
            }
        },
        "spec": {
            "template": {
                "metadata": {
                    "annotations": {
                        "autoscaling.knative.dev/maxScale": "10",
                        "autoscaling.knative.dev/minScale": "0",
                        "run.googleapis.com/cpu-throttling": "true",
                        "run.googleapis.com/execution-environment": "gen2"
                    }
                },
                "spec": {
                    "containerConcurrency": 80,
                    "timeoutSeconds": 300,
                    "containers": [{
                        "image": IMAGE_NAME,
                        "ports": [{
                            "containerPort": 8080,
                            "name": "http1"
                        }],
                        "resources": {
                            "limits": {
                                "cpu": "1000m",
                                "memory": "1Gi"
                            }
                        },
                        "env": [
                            {
                                "name": "FLASK_ENV",
                                "value": "production"
                            },
                            {
                                "name": "FIREBASE_PROJECT_ID",
                                "value": "inventory-3098f"
                            },
                            {
                                "name": "FIREBASE_STORAGE_BUCKET",
                                "value": "inventory-3098f.appspot.com"
                            },
                            {
                                "name": "SESSION_COOKIE_SECURE",
                                "value": "true"
                            },
                            {
                                "name": "PORT",
                                "value": "8080"
                            }
                        ]
                    }]
                }
            }
        }
    }
    
    # Write service config to file
    config_file = "service-config-fixed.json"
    with open(config_file, 'w') as f:
        json.dump(service_config, f, indent=2)
    
    print(f"📝 Created updated service configuration: {config_file}")
    
    # Update the service
    update_url = f"https://{REGION}-run.googleapis.com/apis/serving.knative.dev/v1/namespaces/{PROJECT_ID}/services/{SERVICE_NAME}"
    
    update_cmd = f'''curl -X PUT "{update_url}" \\
      -H "Authorization: Bearer {access_token}" \\
      -H "Content-Type: application/json" \\
      -d @{config_file}'''
    
    print("Updating service configuration...")
    update_result = run_command(update_cmd)
    
    if update_result:
        print("✅ Service updated successfully!")
        
        # 4. Wait for deployment to complete
        print("\n⏳ Waiting for new revision to deploy...")
        time.sleep(30)
        
        # 5. Check service status
        print("\n🔍 Checking deployment status...")
        status_url = f"https://{REGION}-run.googleapis.com/apis/serving.knative.dev/v1/namespaces/{PROJECT_ID}/services/{SERVICE_NAME}"
        
        status_cmd = f'''curl -H "Authorization: Bearer {access_token}" \\
          "{status_url}"'''
        
        service_info = run_command(status_cmd)
        if service_info:
            try:
                info = json.loads(service_info)
                
                # Extract URL from annotations
                urls_annotation = info.get('metadata', {}).get('annotations', {}).get('run.googleapis.com/urls', '[]')
                urls = json.loads(urls_annotation)
                
                if urls and len(urls) > 0:
                    service_url = urls[0]
                    
                    # Check if service is ready
                    conditions = info.get('status', {}).get('conditions', [])
                    ready = False
                    for condition in conditions:
                        if condition['type'] == 'Ready':
                            ready = condition['status'] == 'True'
                            break
                    
                    if ready:
                        print(f"\n🎉 DEPLOYMENT FIXED AND SUCCESSFUL!")
                        print(f"🌐 Your app is live at: {service_url}")
                        print(f"🏥 Health check: {service_url}/health")
                        print(f"📊 Admin dashboard: {service_url}/admin")
                        print(f"💰 Estimated monthly cost: $0-10 (pay-per-use pricing)")
                        print(f"🚀 Your inventory management system is now running 24/7 on Google Cloud Run!")
                    else:
                        print(f"\n⚠️ Service is updating...")
                        print(f"🌐 Your app will be at: {service_url}")
                        print("⏳ Please wait a few more minutes for the deployment to complete")
                        
                        # Show current status
                        for condition in conditions:
                            print(f"  {condition['type']}: {condition['status']}")
                            if condition.get('message'):
                                print(f"    Message: {condition['message']}")
                else:
                    print("❌ Service URL not found in response")
                    
            except json.JSONDecodeError:
                print("❌ Failed to parse service info")
                print("Response:", service_info)
        else:
            print("❌ Failed to get service status")
    else:
        print("❌ Failed to update service")
    
    # Cleanup
    try:
        import os
        os.remove(config_file)
    except:
        pass

if __name__ == "__main__":
    main()
