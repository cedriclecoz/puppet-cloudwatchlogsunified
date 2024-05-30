# @summary Default parameters
class cloudwatchlogsunified::params {
  $region = 'us-east-1'
  $config = '/opt/aws/amazon-cloudwatch-agent/bin/config.json'
  $template_config = 'config.json'
}
