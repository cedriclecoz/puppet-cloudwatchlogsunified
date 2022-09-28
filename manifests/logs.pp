# @summary Add log files to the config
# @example
#   include cloudwatchlogsunified::logs
class cloudwatchlogsunified::logs (
  $path       = '',
  $log_group  = '',
  $log_stream = '',
  $time_zone  = 'LOCAL'
){
  validate_absolute_path($path)

  exec { "${log_group}_${log_stream}_cloudwatchagent":
    path    => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
    command => "flock -x /tmp/toto -c 'jq \'.logs.logs_collected.files.collect_list +=\
      [{\"file_path\":\"${path}\",\
      \"log_group_name\":\"${log_group}\",\
      \"log_stream_name\": \"${log_stream}\"}]\'\
      ${cloudwatchlogsunified::params::config}' > /tmp/config.json; mv /tmp/config.json ${cloudwatchlogsunified::params::config}",
    unless  => "grep ${log_stream} ${cloudwatchlogsunified::params::config}",
    require => File['base_config'],
  }
}
