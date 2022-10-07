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
  $region               = $cloudwatchlogsunified::params::region,
  $logs                 = {},
  $cwagent_uid          = 2222,
  $cwagent_gid          = 2222,
) inherits cloudwatchlogsunified::params {

  validate_hash($logs)
  ensure_packages('wget', {'ensure' => 'latest'})

  group { 'cwagent':
    ensure => 'present',
    gid    => $cwagent_gid,
  }
  user { 'cwagent':
    ensure  => 'present',
    uid     => $cwagent_uid,
    groups  => 'cwagent',
    shell   => '/usr/sbin/nologin'
    require => Group['cwagent'],
  }

  case $facts['os']['family'] {
    'Debian': {
          exec { 'wget-cloudwatchagent':
            path    => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
            command => 'wget -O /tmp/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb',
            unless  => '[ -e /tmp/amazon-cloudwatch-agent.deb ]',
            require => Package['wget'],
          }
          exec { 'install-cloudwatchagent':
            path    => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
            command => 'dpkg -i -E /tmp/amazon-cloudwatch-agent.deb',
            onlyif  => '[ -e /tmp/amazon-cloudwatch-agent.deb ]',
            unless  => '[ -d /opt/aws/amazon-cloudwatch-agent/bin ]',
            require => [
              Exec['wget-cloudwatchagent'],
              User['cwagent'],
            ]
          }
    }
    default: { fail("${module_name} not supported on ${facts['os']['family']}/${facts['os']['distro']}.") }
  }

  file { 'base_config':
    ensure  => 'file',
    path    => $cloudwatchlogsunified::params::config,
    mode    => '0640',
    source  => 'puppet:///modules/cloudwatchlogsunified/config.json',
    replace => 'no',
    require => [ Exec['wget-cloudwatchagent'] ]
  }
  ~> Exec['ReloadAwsLogsConfig']


  exec { 'ReloadAwsLogsConfig':
    path        => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
    command     => "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                   -a fetch-config -m ec2 -s -c file:${cloudwatchlogsunified::params::config}",
    subscribe   => File['base_config'],
    refreshonly => true
  }
}
