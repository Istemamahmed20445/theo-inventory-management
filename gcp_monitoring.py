#!/usr/bin/env python3
"""
Google Cloud Monitoring and Logging Setup
THEO Clothing Inventory Management System
"""

import os
import logging
from flask import Flask
from google.cloud import logging as cloud_logging
from google.cloud import monitoring_v3
from google.cloud.monitoring_v3 import query

def setup_cloud_logging(app: Flask):
    """Set up Google Cloud Logging for the Flask application"""
    try:
        # Initialize Cloud Logging client
        client = cloud_logging.Client()
        
        # Set up Cloud Logging handler
        client.setup_logging()
        
        # Configure Python logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # Create logger for the application
        logger = logging.getLogger(__name__)
        
        # Add Cloud Logging handler
        cloud_handler = cloud_logging.Client().get_default_handler()
        logger.addHandler(cloud_handler)
        
        app.logger.info("Google Cloud Logging initialized successfully")
        return logger
        
    except Exception as e:
        # Fallback to standard logging if Cloud Logging fails
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to initialize Cloud Logging: {e}")
        return logger

def create_custom_metrics():
    """Create custom metrics for application monitoring"""
    try:
        client = monitoring_v3.MetricServiceClient()
        project_name = f"projects/{os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')}"
        
        # Define custom metrics
        metrics = [
            {
                "name": "inventory/products_count",
                "display_name": "Total Products Count",
                "description": "Total number of products in inventory",
                "metric_kind": "GAUGE",
                "value_type": "INT64"
            },
            {
                "name": "inventory/sales_count",
                "display_name": "Sales Count",
                "description": "Number of sales transactions",
                "metric_kind": "COUNTER",
                "value_type": "INT64"
            },
            {
                "name": "inventory/low_stock_alerts",
                "display_name": "Low Stock Alerts",
                "description": "Number of products with low stock",
                "metric_kind": "GAUGE",
                "value_type": "INT64"
            },
            {
                "name": "inventory/active_users",
                "display_name": "Active Users",
                "description": "Number of active users",
                "metric_kind": "GAUGE",
                "value_type": "INT64"
            }
        ]
        
        created_metrics = []
        for metric in metrics:
            try:
                descriptor = monitoring_v3.MetricDescriptor(
                    type=f"custom.googleapis.com/{metric['name']}",
                    metric_kind=getattr(monitoring_v3.MetricDescriptor.MetricKind, metric['metric_kind']),
                    value_type=getattr(monitoring_v3.MetricDescriptor.ValueType, metric['value_type']),
                    description=metric['description'],
                    display_name=metric['display_name']
                )
                
                descriptor = client.create_metric_descriptor(
                    name=project_name, descriptor=descriptor
                )
                created_metrics.append(descriptor)
                print(f"Created metric: {metric['name']}")
                
            except Exception as e:
                print(f"Failed to create metric {metric['name']}: {e}")
        
        return created_metrics
        
    except Exception as e:
        print(f"Failed to create custom metrics: {e}")
        return []

def send_metric(metric_name: str, value: float, labels: dict = None):
    """Send a custom metric to Google Cloud Monitoring"""
    try:
        client = monitoring_v3.MetricServiceClient()
        project_name = f"projects/{os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')}"
        
        series = monitoring_v3.TimeSeries()
        series.metric.type = f"custom.googleapis.com/{metric_name}"
        series.resource.type = "global"
        
        # Add labels if provided
        if labels:
            for key, val in labels.items():
                series.metric.labels[key] = str(val)
        
        # Create data point
        point = monitoring_v3.Point()
        point.value.double_value = value
        point.interval.end_time.seconds = int(time.time())
        series.points = [point]
        
        # Send the time series
        client.create_time_series(name=project_name, time_series=[series])
        
    except Exception as e:
        print(f"Failed to send metric {metric_name}: {e}")

def create_uptime_check(project_id: str, service_url: str):
    """Create an uptime check for the application"""
    try:
        client = monitoring_v3.UptimeCheckServiceClient()
        project_name = f"projects/{project_id}"
        
        # Extract hostname and path from service URL
        from urllib.parse import urlparse
        parsed_url = urlparse(service_url)
        hostname = parsed_url.hostname
        path = parsed_url.path or "/health"
        
        config = monitoring_v3.UptimeCheckConfig(
            display_name="THEO Inventory Health Check",
            monitored_resource=monitoring_v3.UptimeCheckConfig.Resource(
                type="uptime_url",
                labels={
                    "host": hostname,
                    "project_id": project_id
                }
            ),
            http_check=monitoring_v3.UptimeCheckConfig.HttpCheck(
                request_method=monitoring_v3.UptimeCheckConfig.HttpCheck.RequestMethod.GET,
                path=path,
                port=443 if parsed_url.scheme == 'https' else 80,
                use_ssl=parsed_url.scheme == 'https'
            ),
            timeout={"seconds": 10},
            period={"seconds": 60},
            selected_regions=[
                monitoring_v3.UptimeCheckRegion.USA_OREGON,
                monitoring_v3.UptimeCheckRegion.USA_IOWA,
                monitoring_v3.UptimeCheckRegion.EUROPE_IRELAND
            ]
        )
        
        response = client.create_uptime_check_config(
            parent=project_name, uptime_check_config=config
        )
        
        print(f"Created uptime check: {response.name}")
        return response
        
    except Exception as e:
        print(f"Failed to create uptime check: {e}")
        return None

def create_alert_policy(project_id: str, service_name: str):
    """Create alert policies for the application"""
    try:
        client = monitoring_v3.AlertPolicyServiceClient()
        project_name = f"projects/{project_id}"
        
        # Define alert policies
        policies = [
            {
                "display_name": "High Error Rate",
                "description": "Alert when error rate is high",
                "conditions": [
                    {
                        "display_name": "Error rate condition",
                        "condition_threshold": {
                            "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/request_count"',
                            "comparison": "COMPARISON_GREATER_THAN",
                            "threshold_value": 10,
                            "duration": {"seconds": 300}
                        }
                    }
                ],
                "notification_channels": [],  # Add notification channels here
                "alert_strategy": {
                    "auto_close": {"seconds": 3600}
                }
            },
            {
                "display_name": "High Response Time",
                "description": "Alert when response time is high",
                "conditions": [
                    {
                        "display_name": "Response time condition",
                        "condition_threshold": {
                            "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/request_latencies"',
                            "comparison": "COMPARISON_GREATER_THAN",
                            "threshold_value": 2000,  # 2 seconds
                            "duration": {"seconds": 300}
                        }
                    }
                ],
                "notification_channels": [],
                "alert_strategy": {
                    "auto_close": {"seconds": 3600}
                }
            }
        ]
        
        created_policies = []
        for policy_config in policies:
            try:
                policy = monitoring_v3.AlertPolicy(
                    display_name=policy_config["display_name"],
                    documentation=monitoring_v3.AlertPolicy.Documentation(
                        content=policy_config["description"]
                    ),
                    conditions=policy_config["conditions"],
                    notification_channels=policy_config["notification_channels"],
                    alert_strategy=policy_config["alert_strategy"]
                )
                
                response = client.create_alert_policy(
                    name=project_name, alert_policy=policy
                )
                created_policies.append(response)
                print(f"Created alert policy: {policy_config['display_name']}")
                
            except Exception as e:
                print(f"Failed to create alert policy {policy_config['display_name']}: {e}")
        
        return created_policies
        
    except Exception as e:
        print(f"Failed to create alert policies: {e}")
        return []

def setup_monitoring_dashboard(project_id: str, service_name: str):
    """Create a monitoring dashboard for the application"""
    try:
        from google.cloud import monitoring_dashboard_v1
        
        client = monitoring_dashboard_v1.DashboardsServiceClient()
        project_name = f"projects/{project_id}"
        
        # Define dashboard configuration
        dashboard = monitoring_dashboard_v1.Dashboard(
            display_name="THEO Inventory Management Dashboard",
            mosaic_layout=monitoring_dashboard_v1.MosaicLayout(
                tiles=[
                    {
                        "width": 6,
                        "height": 4,
                        "widget": {
                            "title": "Request Count",
                            "xy_chart": {
                                "data_sets": [
                                    {
                                        "time_series_query": {
                                            "time_series_filter": {
                                                "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/request_count"',
                                                "aggregation": {
                                                    "alignment_period": {"seconds": 300},
                                                    "per_series_aligner": "ALIGN_RATE"
                                                }
                                            }
                                        },
                                        "plot_type": "LINE"
                                    }
                                ]
                            }
                        }
                    },
                    {
                        "width": 6,
                        "height": 4,
                        "widget": {
                            "title": "Response Time",
                            "xy_chart": {
                                "data_sets": [
                                    {
                                        "time_series_query": {
                                            "time_series_filter": {
                                                "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/request_latencies"',
                                                "aggregation": {
                                                    "alignment_period": {"seconds": 300},
                                                    "per_series_aligner": "ALIGN_MEAN"
                                                }
                                            }
                                        },
                                        "plot_type": "LINE"
                                    }
                                ]
                            }
                        }
                    },
                    {
                        "width": 6,
                        "height": 4,
                        "widget": {
                            "title": "Error Rate",
                            "xy_chart": {
                                "data_sets": [
                                    {
                                        "time_series_query": {
                                            "time_series_filter": {
                                                "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/request_count" AND metric.labels.response_code_class!="2xx"',
                                                "aggregation": {
                                                    "alignment_period": {"seconds": 300},
                                                    "per_series_aligner": "ALIGN_RATE"
                                                }
                                            }
                                        },
                                        "plot_type": "LINE"
                                    }
                                ]
                            }
                        }
                    },
                    {
                        "width": 6,
                        "height": 4,
                        "widget": {
                            "title": "Active Instances",
                            "xy_chart": {
                                "data_sets": [
                                    {
                                        "time_series_query": {
                                            "time_series_filter": {
                                                "filter": f'resource.type="cloud_run_revision" AND resource.labels.service_name="{service_name}" AND metric.type="run.googleapis.com/container/instance_count"',
                                                "aggregation": {
                                                    "alignment_period": {"seconds": 300},
                                                    "per_series_aligner": "ALIGN_MEAN"
                                                }
                                            }
                                        },
                                        "plot_type": "LINE"
                                    }
                                ]
                            }
                        }
                    }
                ]
            )
        )
        
        response = client.create_dashboard(
            parent=project_name, dashboard=dashboard
        )
        
        print(f"Created monitoring dashboard: {response.name}")
        return response
        
    except Exception as e:
        print(f"Failed to create monitoring dashboard: {e}")
        return None

def main():
    """Main function to set up all monitoring components"""
    import time
    
    project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'your-project-id')
    service_name = 'theo-inventory'
    service_url = f'https://{service_name}-{project_id}.a.run.app'
    
    print("Setting up Google Cloud Monitoring...")
    
    # Create custom metrics
    print("Creating custom metrics...")
    create_custom_metrics()
    
    # Create uptime check
    print("Creating uptime check...")
    create_uptime_check(project_id, service_url)
    
    # Create alert policies
    print("Creating alert policies...")
    create_alert_policy(project_id, service_name)
    
    # Create monitoring dashboard
    print("Creating monitoring dashboard...")
    setup_monitoring_dashboard(project_id, service_name)
    
    print("Monitoring setup completed!")

if __name__ == "__main__":
    main()
