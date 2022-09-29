# @summary Add log files to the config
#
# This part is... bad. I am not sure how to update a json file easily.
# Using jq tool here allows to add new logs to the json.
# Note: it is not possible to remove out some logs, or update a CW log_stream for a specific
# file once it's set.
# If for example a log_stream to a specific file was modified in the calling manifest,
# then it would just create a second entry, and it's likely the log would be uploaded to both CW log.
#
# I also made use of flock here in order to block 2 writes to the same file at the same time.
#
#
# @example
#   include cloudwatchlogsunified::logs
define cloudwatchlogsunified::logs (
  $path       = '',
  $log_group  = '',
  $log_stream = '',
  $time_zone  = 'LOCAL'
){
  validate_absolute_path($path)
  ensure_packages(['jq',], {'ensure' => 'latest'})

  exec { "${log_group}_${log_stream}_cloudwatchagent":
    path    => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
    command => "flock -x /tmp/flock -c \"jq '.logs.logs_collected.files.collect_list +=\
      [{\\\"file_path\\\":\\\"${path}\\\",\
      \\\"log_group_name\\\":\\\"${log_group}\\\",\
      \\\"log_stream_name\\\": \\\"${log_stream}\\\"}]'\
      ${cloudwatchlogsunified::params::config} > /tmp/config.json; \
      mv /tmp/config.json ${cloudwatchlogsunified::params::config}\"",
    unless  => "cat ${cloudwatchlogsunified::params::config} | jq -e '(.logs.logs_collected.files.collect_list[]\
                | select((.file_path == \"${path}\") and (.log_group_name == \"${log_group}\") and \
                         (.log_stream_name == \"${log_stream}\")))'\
                ; if [ $? -eq 0 ]; then exit 0; else exit 1; fi",
    require => [File['base_config'], Package['jq']],
  } ~> Exec['ReloadAwsLogsConfig']
}
