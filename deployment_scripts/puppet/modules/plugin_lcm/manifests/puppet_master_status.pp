# == Class plugin_lcm::puppet_master_status
#
# Create the 'puppet-master-status' script that
# can check if the puppet is running in the standalone
# mode using the puppet's pid file and configures
# the puppet service to use this script to get
# the service status.
#
# Shows the correct status if Puppet is running
# in the passenger mode.
#
class plugin_lcm::puppet_master_status {
  $script_path = '/usr/local/bin/puppet-master-status'

  file { 'puppet-master-status' :
    ensure  => 'present',
    path    => $script_path,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('plugin_lcm/puppet-master-status.sh.erb'),
  }

  ~>

  Service <| title == 'puppetmaster' |> {
    hasrestart => true,
    hasstatus  => true,
    provider   => 'debian',
    status     => $script_path,
  }

}
