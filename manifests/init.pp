# @summary Install and configure AWS Cloudwatch Logs.
#
# Nothing much to add for now.
#
# @example
#   include cloudwatchlogsunified
#
# @maintainer cedric.le.coz@rdkcentral.com
#
class cloudwatchlogsunified (
  $region               = $cloudwatchlogsunified::params::region
  $logs                 = {}
) inherits cloudwatchlogsunified::params {

  validate_hash($logs)

  case $facts['os']['family'] {
    'Ubuntu': {
          exec { 'wget-cloudwatchagent':
            path    => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
            command => 'wget -O /tmp/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb',
            unless  => '[ -e /usr/local/src/awslogs-agent-setup.py ]',
            require => Package['wget'],
          }
    }
    default: { fail("${module_name} not supported on ${facts['os'['family']}/${facts['os']['distro']}.") }
  }
}
