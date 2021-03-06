Exec {
  path => ['/usr/local/sbin', '/usr/sbin', '/sbin', '/usr/local/bin', '/usr/bin', '/bin'],
}

if $operatingsystem == "Ubuntu" {

  # Ensure apt database has been updated before any packages are installed
  Exec['apt-get-update'] -> Package<| |>

  exec { 'add-ansible-repo':
    command   => 'add-apt-repository -y ppa:rquillo/ansible',
    creates   => '/etc/apt/trusted.gpg.d/rquillo-ansible.gpg',
    logoutput => true,
  }

  exec { 'apt-get-update':
    command => 'apt-get update',
    onlyif  => '[ $(($(date +%s) - $(date +%s -d "$(stat -c %y /var/lib/apt/periodic/update-success-stamp)"))) -gt 3600 ]',
    require => Exec['add-ansible-repo'],
  }

} elsif $operatingsystem == "CentOS" {

  # Ensure epel repo is installed before any packaged are installed
  Exec['install-epel'] -> Package<| |>

  $epel_url = 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'

  exec { 'install-epel':
    command => "rpm -Uvh $epel_url",
    unless  => "yum repolist | grep '^epel '",
  }
}

package { 'ansible':
  ensure => installed,
}

file { '/etc/ansible/hosts':
  source  => '/vagrant/provisioning/ansible/config/hosts',
  mode    => '0644',
  require => Package['ansible'],
}
