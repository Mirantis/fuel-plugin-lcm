# == Class: r10k::make_env
#
# Create local puppet environments from remote branches
#

class r10k::make_env {

  exec { 'make-env':
    command   => 'r10k deploy environment -pv',
    cwd       => '/etc/puppet/environments',
    path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
    logoutput => 'on_failure',
    provider  => 'shell',
    timeout   => '1800',
  }

}
